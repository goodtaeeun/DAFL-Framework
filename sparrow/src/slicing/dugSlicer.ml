open Vocab
open Global
open BasicDom
open SlicingUtils
open DefUse
module L = Logging
module PowAlloc = PowDom.MakeCPO (BasicDom.Allocsite)
module Val = ItvDom.Val
module Mem = ItvDom.Mem
module AccessAnalysis = AccessAnalysis.Make (AccessSem.SlicingSem)
module Access = AccessAnalysis.Access
module DUGraph = Dug.Make (Access)
module SsaDug = SsaDug.Make (DUGraph)

let memoize = Hashtbl.create 10000

(* Module to compute allocsites (i.e. heap allocations) that are reachable from
 * each function. *)
module ReachableAlloc = struct
  type t = {
    global_reachables : PowAlloc.t;
    local_reachables : (Proc.t, PowAlloc.t) BatMap.t;
  }

  let empty =
    { global_reachables = PowAlloc.empty; local_reachables = BatMap.empty }

  let collect_allocsite locs =
    let rec folder l acc =
      match l with
      | Loc.GVar _ | Loc.LVar _ | Loc.Allocsite (Local _) -> acc
      | Loc.Allocsite a -> PowAlloc.add a acc
      | Loc.Field (l', _, _) -> folder l' acc
    in
    PowLoc.fold folder locs PowAlloc.empty

  let expand_allocs allocs locs =
    let rec is_derivable = function
      | Loc.GVar _ | Loc.LVar _ | Loc.Allocsite (Local _) -> false
      | Loc.Allocsite a -> PowAlloc.mem a allocs
      | Loc.Field (l, _, _) -> is_derivable l
    in
    PowLoc.filter is_derivable locs

  let rec trace_aux mem fields reach_map reachable locs =
    let folder l (acc_reachable, acc_next_lookup) =
      if BatMap.mem l reach_map then
        (* If it's already resolved, lookup 'reach_map' (i.e. memoize) *)
        let reachable_from_l = BatMap.find l reach_map in
        let acc_reachable = PowLoc.union reachable_from_l acc_reachable in
        (acc_reachable, acc_next_lookup)
      else
        (* Lookup 'l' and find locations and allocs pointed by it *)
        let pointed_locs = Mem.find l mem |> Val.all_locs in
        let allocs = collect_allocsite pointed_locs in
        let additional_locs = expand_allocs allocs fields in
        let pointed_locs = PowLoc.union pointed_locs additional_locs in
        let new_locs = PowLoc.diff pointed_locs acc_reachable in
        let acc_reachable = PowLoc.union new_locs acc_reachable in
        let acc_next_lookup = PowLoc.union new_locs acc_next_lookup in
        (acc_reachable, acc_next_lookup)
    in
    let reachable, next_lookup =
      PowLoc.fold folder locs (reachable, PowLoc.empty)
    in
    (* Recurse until there's no more new location to trace into *)
    if PowLoc.is_empty next_lookup then reachable
    else trace_aux mem fields reach_map reachable next_lookup

  let trace mem fields reach_map start_loc =
    trace_aux mem fields reach_map PowLoc.empty (PowLoc.singleton start_loc)

  (* Construct a mapping from each location to its reachable location set *)
  let construct_reach_map mem locs =
    let fields = PowLoc.filter Loc.is_field locs in
    let heap_locs = PowLoc.filter Loc.is_heap locs in
    let non_heap_locs = PowLoc.filter (fun l -> not (Loc.is_heap l)) locs in
    let folder l acc_map =
      let reachable_locs = trace mem fields acc_map l in
      BatMap.add l reachable_locs acc_map
    in
    (* Should traverse heap locations first, for effective memoization *)
    PowLoc.fold folder heap_locs BatMap.empty
    |> PowLoc.fold folder non_heap_locs

  let compute global =
    let pids = InterCfg.pidsof global.icfg in
    let locs = ItvDom.Mem.keys global.mem in
    let reach_map = construct_reach_map global.mem locs in
    let retrieve_reachable_allocs locs =
      let folder l acc = PowLoc.union (BatMap.find l reach_map) acc in
      PowLoc.fold folder locs PowLoc.empty |> collect_allocsite
    in
    let globals = PowLoc.filter Loc.is_global locs in
    let global_reachables = retrieve_reachable_allocs globals in
    let folder f acc =
      let f_locals = PowLoc.filter (Loc.is_local_of f) locs in
      let f_reachables = retrieve_reachable_allocs f_locals in
      BatMap.add f f_reachables acc
    in
    let local_reachables = list_fold folder pids BatMap.empty in
    { global_reachables; local_reachables }

  let lookup trans_caller reachability =
    let global_reachables = reachability.global_reachables in
    let local_reachables = reachability.local_reachables in
    let folder f acc =
      if not (BatMap.mem f local_reachables) then acc
      else PowAlloc.union (BatMap.find f local_reachables) acc
    in
    PowProc.fold folder trans_caller global_reachables
end

(* Check if the given location is live (valid) at the current point. *)
let rec is_accessible is_ret callee trans_caller reachable_alloc = function
  | Loc.GVar _ -> true
  | Loc.LVar (p, v, _) ->
      PowProc.mem p trans_caller
      || (is_ret && v = Loc.return_var_name && PowProc.mem p callee)
  | Loc.Allocsite (Local n) -> PowProc.mem (Node.get_pid n) trans_caller
  | Loc.Allocsite a -> PowAlloc.mem a reachable_alloc
  | Loc.Field (l, _, _) ->
      is_accessible is_ret callee trans_caller reachable_alloc l

(* Compute transitive caller when the current function is 'f' and call context
 * is 'ctx'. Note that the last element in 'f :: ctx' is the function where we
 * started to trace into a callee function. *)
let compute_trans_callers f ctx callgraph =
  let rec expand = function
    | [] -> failwith "Unreachable"
    | [ x ] -> PowProc.add x (CallGraph.trans_callers x callgraph)
    | head :: tail -> PowProc.add head (expand tail)
  in
  expand (f :: ctx)

let filter_accessible global reach f ctx is_ret locs =
  let callee = CallGraph.callees f global.callgraph in
  let trans_caller = compute_trans_callers f ctx global.callgraph in
  let reachable_alloc = ReachableAlloc.lookup trans_caller reach in
  PowLoc.filter (is_accessible is_ret callee trans_caller reachable_alloc) locs

let construct_dug global slicing_targets =
  let iterator (_, targ_str) = SlicingUtils.register_target global targ_str in
  List.iter iterator slicing_targets;
  let locset = ItvAnalysis.get_locset global.mem in
  (* We do not use semantics function to compute DU *)
  let dummy_sem _ (mem, global) = (mem, global) in
  let f_access = AccessAnalysis.perform global locset dummy_sem in
  let access = StepManager.stepf false "Access Analysis" f_access global.mem in
  let init = (global, access, locset) in
  let dug = StepManager.stepf false "DUG construction" SsaDug.make init in
  prerr_memory_usage ();
  dug

let initialize global targ_nodes =
  let slice = SliceDFG.init targ_nodes in
  let folder n (acc_visited, acc_works) =
    let uses = eval_use_of_targ global global.mem n in
    Printf.printf "Uses of %s: %s\n"
      (node_to_lstr_verbose global n)
      (PowLoc.to_string uses);
    SliceDFG.update_use_map n uses slice;
    (VisitLog.add n uses acc_visited, (n, uses) :: acc_works)
  in
  let visited, works = NodeSet.fold folder targ_nodes (VisitLog.empty, []) in
  (slice, visited, works)

let update_works node forward used visited works =
  let visited, new_fwds = VisitLog.update node forward visited in
  let visited, new_uses = VisitLog.update node used visited in
  let has_fwd = not (PowLoc.is_empty new_fwds) in
  let has_use = not (PowLoc.is_empty new_uses) in
  let works = if has_fwd then (node, new_fwds) :: works else works in
  let works = if has_use then (node, new_uses) :: works else works in
  (visited, works)

(* Note that transfer function for a call node is subsumed here *)
let transfer_normal global ctx node uses p (slice, visited, works) =
  let is_callee = not (is_list_empty ctx) in
  let node_f = InterCfg.Node.get_pid node in
  let p_f = InterCfg.Node.get_pid p in
  let _ =
    if node_f <> p_f then
      Printf.printf "Function changes: p_f = %s node_f = %s, uses = %s\n" p_f
        node_f (PowLoc.to_string uses)
  in
  let pred_du = eval_def_use global global.mem p in
  let forward = PowLoc.diff uses pred_du.defs in
  let defined = PowLoc.inter uses pred_du.defs in
  let used = DefUseInfo.lookup_defs defined pred_du in
  let slice =
    if is_callee then
      if PowLoc.is_empty defined then slice
      else SliceDFG.add_sliced_node p slice
    else
      SliceDFG.draw_edge_fwd p node forward slice
      |> SliceDFG.draw_edge_def p node defined used
  in
  let visited, works = update_works p forward used visited works in
  (slice, visited, works)

let skip_ret global node uses p (slice, visited, works) =
  let caller = InterCfg.Node.get_pid node in
  let callee = InterCfg.Node.get_pid p in
  let _ =
    Printf.printf "From %s (%s), ignore return from %s()\n"
      (node_to_lstr global node) caller callee
  in
  let call_node = InterCfg.callof node global.icfg in
  let slice = SliceDFG.draw_edge_fwd call_node node uses slice in
  let visited, works = update_works call_node uses PowLoc.empty visited works in
  (slice, visited, works)

(* Find out which locations were used by this callee to define 'uses' *)
let rec find_callee_use global reach dug ctx uses exit_node slice =
  let callee = InterCfg.Node.get_pid exit_node in
  if Hashtbl.mem memoize (callee, uses) then
    let u = Hashtbl.find memoize (callee, uses) in
    (u, slice)
  else
    let visited = VisitLog.add exit_node uses VisitLog.empty in
    let works = [ (exit_node, uses) ] in
    let u, slice =
      trace_callee global reach dug ctx callee PowLoc.empty slice visited works
    in
    let _ = Hashtbl.replace memoize (callee, uses) u in
    (u, slice)

(* Transfer function when 'node' is a return node and 'p' is an exit node. *)
and transfer_ret global reach ctx dug node uses p (slice, visited, works) =
  let is_callee = not (is_list_empty ctx) in
  let caller = InterCfg.Node.get_pid node in
  let callee = InterCfg.Node.get_pid p in
  let _ =
    Printf.printf "From %s (%s), trace into %s() for uses = %s, ctx = %s\n"
      (node_to_lstr global node) caller callee (PowLoc.to_string uses)
      ("[" ^ String.concat " --> " (List.rev ctx) ^ "]")
  in
  let ctx = InterCfg.Node.get_pid node :: ctx in
  let use_at_entry, slice = find_callee_use global reach dug ctx uses p slice in
  let _ =
    Printf.printf "Traced function %s used %s to define %s\n" callee
      (PowLoc.to_string use_at_entry)
      (PowLoc.to_string uses)
  in
  let call_node = InterCfg.callof node global.icfg in
  let call_du = eval_def_use global global.mem call_node in
  let forward = PowLoc.diff use_at_entry call_du.defs in
  let defined = PowLoc.inter use_at_entry call_du.defs in
  let used = DefUseInfo.lookup_defs defined call_du in
  let slice =
    if is_callee then
      if PowLoc.is_empty defined then slice
      else SliceDFG.add_sliced_node call_node slice
    else (
      (* We will think that 'call_node' defines/forwards 'use_at_entry' to
       * 'node' (which is a return node), and 'node' defines 'uses' with it. *)
      SliceDFG.update_def_map node uses slice;
      SliceDFG.update_use_map node use_at_entry slice;
      SliceDFG.add_edge_owner node slice
      |> SliceDFG.draw_edge_fwd call_node node forward
      |> SliceDFG.draw_edge_def call_node node defined used)
  in
  let visited, works = update_works call_node forward used visited works in
  (slice, visited, works)

and transfer global reach dug ctx node uses (slice, visited, works) =
  let node_f = InterCfg.Node.get_pid node in
  let is_entry = InterCfg.is_entry node in
  let is_ret = InterCfg.is_returnnode node global.icfg in
  let orig_uses = uses in
  let uses =
    if !Options.unfiltered_slice then uses
    else filter_accessible global reach node_f ctx is_ret uses
  in
  let diff = PowLoc.diff orig_uses uses in
  if not (PowLoc.is_empty diff) then
    Printf.printf "Filtered out from %s (%s): %s\n" (node_to_lstr global node)
      node_f (PowLoc.to_string diff);
  let preds = DUGraph.pred node dug in
  let folder p (slice, visited, works) =
    let p_f = InterCfg.Node.get_pid p in
    let locs_on_edge = DUGraph.get_abslocs p node dug in
    let uses = PowLoc.inter locs_on_edge uses in
    if PowLoc.is_empty uses then (slice, visited, works)
    else if is_entry && BatSet.mem (p_f, node_f) global.cyclic_calls then
      (slice, visited, works)
    else if is_ret && InterCfg.is_exit p then
      if BatSet.mem (node_f, p_f) global.cyclic_calls then
        skip_ret global node uses p (slice, visited, works)
      else if !Options.ctx_insen_slice then
        transfer_normal global ctx node uses p (slice, visited, works)
      else transfer_ret global reach ctx dug node uses p (slice, visited, works)
    else transfer_normal global ctx node uses p (slice, visited, works)
  in
  list_fold folder preds (slice, visited, works)

(* Trace DUG until we reach the entry of 'callee'. Note that this does not mean
 * we trace intra-procedurally, since 'callee' can also call a function. *)
and trace_callee global reach dug ctx callee acc_uses slice visited works =
  match works with
  | [] -> (acc_uses, slice)
  | (node, uses) :: works when InterCfg.is_entry node ->
      let callee_check = InterCfg.Node.get_pid node in
      let _ = if callee <> callee_check then failwith "Unexpected" in
      let acc_uses = PowLoc.union uses acc_uses in
      trace_callee global reach dug ctx callee acc_uses slice visited works
  | (node, uses) :: works ->
      let slice, visited, works =
        transfer global reach dug ctx node uses (slice, visited, works)
      in
      trace_callee global reach dug ctx callee acc_uses slice visited works

let rec trace_trunk global reach dug slice visited works =
  match works with
  | [] -> slice
  | (node, uses) :: works ->
      let slice, visited, works =
        transfer global reach dug [] node uses (slice, visited, works)
      in
      trace_trunk global reach dug slice visited works

let print_to_file targ_id filename str_set =
  let slicing_dir = Filename.concat !Options.outdir targ_id in
  FileManager.mkdir slicing_dir;
  let oc = open_out (Filename.concat slicing_dir filename) in
  SS.iter (fun str -> output_string oc (str ^ "\n")) str_set;
  close_out oc

let dump_funcs global =
  let oc = open_out (Filename.concat !Options.outdir "func.txt") in
  let nodes = InterCfg.nodesof global.icfg in
  let folder n acc =
    if is_func_invalid global n then acc else SS.add (node_to_fstr global n) acc
  in
  let funcs = list_fold folder nodes SS.empty in
  SS.iter (fun s -> output_string oc (s ^ "\n")) funcs

let perform_slicing global reach dug (targ_id, targ_line) =
  Printf.printf "Slicing for target '%s' begins\n%!" targ_id;
  Hashtbl.reset memoize;
  let t0 = Sys.time () in
  let targ_nodes = find_target_node_set global targ_line in
  let targ_func = find_target_func global targ_nodes in
  let slice, visited, works = initialize global targ_nodes in
  let slice = trace_trunk global reach dug slice visited works in
  Printf.printf "trace_trunk() finished\n%!";
  let slice_nodes = SliceDFG.get_sliced_nodes slice in
  (* We will always include the entry function (i.e. 'main') nodes, because AFL
   * requires at least one node is covered by the initial test cases. *)
  let entry_nodes = InterCfg.nodes_of_pid global.icfg !Options.entry_point in
  let nodes = NodeSet.union slice_nodes (NodeSet.of_list entry_nodes) in
  let folder n acc = SS.add (node_to_lstr global n) acc in
  let lines = NodeSet.fold folder nodes SS.empty in
  let folder n acc =
    if is_func_invalid global n then acc else SS.add (node_to_fstr global n) acc
  in
  let funcs = NodeSet.fold folder nodes SS.empty in
  let t1 = Sys.time () in
  Printf.printf "Enreting SliceDFG.get_du_edges()\n%!";
  let edges = SliceDFG.get_du_edges slice in
  let t2 = Sys.time () in
  let line_dfg = OutputDFG.init global targ_func targ_line edges in
  let t3 = Sys.time () in
  let dfg_nodes = OutputDFG.stringfy_nodes global line_dfg in
  let t4 = Sys.time () in
  L.info ~to_consol:true "Slicing for %s finished: %f sec\n" targ_id (t4 -. t0);
  L.info ~to_consol:true "DUG traversal time: %f sec\n" (t1 -. t0);
  L.info ~to_consol:true "Edge extraction time: %f sec\n" (t2 -. t1);
  L.info ~to_consol:true "Output DFG initialization time: %f sec\n" (t3 -. t2);
  L.info ~to_consol:true "Output DFG processing time: %f sec\n" (t4 -. t3);
  L.info ~to_consol:true "== Slicing report ==\n";
  L.info ~to_consol:true " - # DUG nodes  : %d\n" (DUGraph.nb_node dug);
  L.info ~to_consol:true " - # DUG edges  : %d\n" (DUGraph.nb_edge dug);
  L.info ~to_consol:true " - # DUG locs   : %d\n" (DUGraph.nb_loc dug);
  L.info ~to_consol:true " - # Sliced nodes : %d\n" (NodeSet.cardinal nodes);
  L.info ~to_consol:true " - # Sliced lines : %d\n" (SS.cardinal lines);
  L.info ~to_consol:true " - # Sliced funcs : %d\n" (SS.cardinal funcs);
  L.info ~to_consol:true " - # Output DFG nodes : %d\n" (SS.cardinal dfg_nodes);
  print_to_file targ_id "slice_line.txt" lines;
  print_to_file targ_id "slice_func.txt" funcs;
  print_to_file targ_id "slice_dfg.txt" dfg_nodes

let run global =
  let slicing_targets = BatMap.bindings !Options.slice_target_map in
  let dug = construct_dug global slicing_targets in
  let t0 = Sys.time () in
  let reach =
    if !Options.unfiltered_slice then ReachableAlloc.empty
    else ReachableAlloc.compute global
  in
  let t1 = Sys.time () in
  L.info ~to_consol:true "Reachability analysis finished: %f sec\n" (t1 -. t0);
  List.iter (perform_slicing global reach dug) slicing_targets;
  L.info "Total elapsed time: ";
  print_elapsed_time ~level:0
