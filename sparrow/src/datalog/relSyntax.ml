open IntraCfg
open Cmd
module F = Format
module Node = InterCfg.Node

type formatter = {
  (* Function body *)
  func : F.formatter;
  (* Command *)
  entry : F.formatter;
  exit : F.formatter;
  join : F.formatter;
  skip : F.formatter;
  assign : F.formatter;
  assume : F.formatter;
  alloc : F.formatter;
  salloc : F.formatter;
  call : F.formatter;
  libcall : F.formatter;
  arg : F.formatter;
  return : F.formatter;
  cmd : F.formatter;
  (* Expressions *)
  const_exp : F.formatter;
  lval_exp : F.formatter;
  binop_exp : F.formatter;
  unop_exp : F.formatter;
  cast_exp : F.formatter;
  other_exp : F.formatter;
  global_var : F.formatter;
  local_var : F.formatter;
  field : F.formatter;
  lval : F.formatter;
  mem : F.formatter;
  start_of : F.formatter;
  (* BinOp *)
  plusa : F.formatter;
  pluspi : F.formatter;
  indexpi : F.formatter;
  minusa : F.formatter;
  minuspi : F.formatter;
  minuspp : F.formatter;
  mult : F.formatter;
  div : F.formatter;
  modd : F.formatter;
  shiftlt : F.formatter;
  shiftrt : F.formatter;
  lt : F.formatter;
  gt : F.formatter;
  le : F.formatter;
  ge : F.formatter;
  eq : F.formatter;
  ne : F.formatter;
  band : F.formatter;
  bxor : F.formatter;
  bor : F.formatter;
  landd : F.formatter;
  lorr : F.formatter;
  (* UnOp *)
  bnot : F.formatter;
  lnot : F.formatter;
  neg : F.formatter;
}

let binop_count = ref 0

let binop_map = Hashtbl.create 1000

let new_binop_id bop =
  let id = "BinOp-" ^ string_of_int !binop_count in
  binop_count := !binop_count + 1;
  Hashtbl.add binop_map bop id;
  id

let unop_count = ref 0

let unop_map = Hashtbl.create 1000

let new_unop_id uop =
  let id = "UnOp-" ^ string_of_int !unop_count in
  binop_count := !binop_count + 1;
  Hashtbl.add unop_map uop id;
  id

let exp_count = ref 0

let exp_map = Hashtbl.create 1000

let new_exp_id e =
  let id = "Exp-" ^ string_of_int !exp_count in
  exp_count := !exp_count + 1;
  Hashtbl.add exp_map e id;
  id

let lv_count = ref 0

let lv_map = Hashtbl.create 1000

let new_lv_id lv =
  let id = "Lval-" ^ string_of_int !lv_count in
  lv_count := !lv_count + 1;
  Hashtbl.add lv_map lv id;
  id

let pp_binop fmt bop =
  if Hashtbl.mem binop_map bop then ()
  else
    let id = new_binop_id bop in
    match bop with
    | Cil.PlusA -> F.fprintf fmt.plusa "%s\n" id
    | PlusPI -> F.fprintf fmt.pluspi "%s\n" id
    | IndexPI -> F.fprintf fmt.indexpi "%s\n" id
    | MinusA -> F.fprintf fmt.minusa "%s\n" id
    | MinusPI -> F.fprintf fmt.minuspi "%s\n" id
    | MinusPP -> F.fprintf fmt.minuspp "%s\n" id
    | Mult -> F.fprintf fmt.mult "%s\n" id
    | Div -> F.fprintf fmt.div "%s\n" id
    | Mod -> F.fprintf fmt.modd "%s\n" id
    | Shiftlt -> F.fprintf fmt.shiftlt "%s\n" id
    | Shiftrt -> F.fprintf fmt.shiftrt "%s\n" id
    | Lt -> F.fprintf fmt.lt "%s\n" id
    | Gt -> F.fprintf fmt.gt "%s\n" id
    | Le -> F.fprintf fmt.le "%s\n" id
    | Ge -> F.fprintf fmt.ge "%s\n" id
    | Eq -> F.fprintf fmt.eq "%s\n" id
    | Ne -> F.fprintf fmt.ne "%s\n" id
    | BAnd -> F.fprintf fmt.band "%s\n" id
    | BXor -> F.fprintf fmt.bxor "%s\n" id
    | BOr -> F.fprintf fmt.bor "%s\n" id
    | LAnd -> F.fprintf fmt.landd "%s\n" id
    | LOr -> F.fprintf fmt.lorr "%s\n" id

let pp_unop fmt uop =
  if Hashtbl.mem unop_map uop then ()
  else
    let id = new_unop_id uop in
    match uop with
    | Cil.BNot -> F.fprintf fmt.bnot "%s\n" id
    | LNot -> F.fprintf fmt.lnot "%s\n" id
    | Neg -> F.fprintf fmt.neg "%s\n" id

let rec pp_lv fmt lv =
  if Hashtbl.mem lv_map lv then ()
  else
    let id = new_lv_id lv in
    match lv with
    | Cil.Var vi, Cil.NoOffset ->
        if vi.Cil.vglob then F.fprintf fmt.global_var "%s\t%s\n" id vi.vname
        else F.fprintf fmt.local_var "%s\t%s\n" id vi.vname
    | Cil.Var _, Cil.Field (_, _) -> F.fprintf fmt.field "%s\n" id
    | Cil.Mem e, offset ->
        pp_exp fmt e;
        (match offset with
        | Cil.Field (_, _) -> F.fprintf fmt.field "%s\n" id
        | _ -> ());
        let e_id = Hashtbl.find exp_map e in
        F.fprintf fmt.mem "%s\t%s\n" id e_id
    | _, _ -> F.fprintf fmt.lval "%s\tOther\n" id

and pp_exp fmt e =
  if Hashtbl.mem exp_map e then ()
  else
    let id = new_exp_id e in
    match e with
    | Cil.Const _ -> F.fprintf fmt.const_exp "%s\n" id
    | Cil.Lval lv ->
        pp_lv fmt lv;
        let lv_id = Hashtbl.find lv_map lv in
        F.fprintf fmt.lval_exp "%s\t%s\n" id lv_id
    | Cil.BinOp (bop, e1, e2, _) ->
        pp_binop fmt bop;
        pp_exp fmt e1;
        pp_exp fmt e2;
        let e1_id = Hashtbl.find exp_map e1 in
        let e2_id = Hashtbl.find exp_map e2 in
        let bop_id = Hashtbl.find binop_map bop in
        F.fprintf fmt.binop_exp "%s\t%s\t%s\t%s\n" id bop_id e1_id e2_id
    | Cil.UnOp (unop, e, _) ->
        pp_exp fmt e;
        pp_unop fmt unop;
        let e_id = Hashtbl.find exp_map e in
        let unop_id = Hashtbl.find unop_map unop in
        F.fprintf fmt.unop_exp "%s\t%s\t%s\n" id unop_id e_id
    | Cil.CastE (_, e1) ->
        pp_exp fmt e1;
        let e1_id = Hashtbl.find exp_map e1 in
        F.fprintf fmt.cast_exp "%s\t%s\n" id e1_id
    | Cil.StartOf l ->
        pp_lv fmt l;
        let l_id = Hashtbl.find lv_map l in
        F.fprintf fmt.start_of "%s\t%s\n" id l_id
    | _ -> F.fprintf fmt.other_exp "%s\n" id

let pp_cmd fmt icfg n =
  if InterCfg.pred n icfg |> List.length = 2 then
    F.fprintf fmt.join "%a\n" Node.pp n;
  F.fprintf fmt.func "%s\t%a\n" (Node.get_pid n) Node.pp n;
  match InterCfg.cmdof icfg n with
  | Cskip _ ->
      if InterCfg.is_entry n then F.fprintf fmt.entry "%a\n" Node.pp n
      else if InterCfg.is_exit n then F.fprintf fmt.exit "%a\n" Node.pp n
      else F.fprintf fmt.skip "%a\n" Node.pp n
  | Cset (lv, e, _) ->
      pp_lv fmt lv;
      pp_exp fmt e;
      let lv_id = Hashtbl.find lv_map lv in
      let e_id = Hashtbl.find exp_map e in
      F.fprintf fmt.assign "%a\t%s\t%s\n" Node.pp n lv_id e_id
  | Cexternal (_, _) -> F.fprintf fmt.cmd "external\n"
  | Calloc (lv, Array e, _, _, _) ->
      pp_lv fmt lv;
      pp_exp fmt e;
      let lv_id = Hashtbl.find lv_map lv in
      let e_id = Hashtbl.find exp_map e in
      F.fprintf fmt.alloc "%a\t%s\t%s\n" Node.pp n lv_id e_id
  | Calloc (_, _, _, _, _) -> F.fprintf fmt.cmd "alloc\n"
  | Csalloc (lv, _, _) ->
      pp_lv fmt lv;
      let lv_id = Hashtbl.find lv_map lv in
      F.fprintf fmt.salloc "%a\t%s\n" Node.pp n lv_id
  | Cfalloc (_, _, _) -> F.fprintf fmt.cmd "falloc\n"
  | Ccall (_, (Lval (Var f, NoOffset) as e), el, _) when f.vstorage = Cil.Extern
    ->
      pp_exp fmt e;
      List.iter (pp_exp fmt) el;
      let id = Hashtbl.find exp_map e in
      F.fprintf fmt.libcall "%a\t%s\n" Node.pp n id
  | Ccall (_, e, el, _) ->
      pp_exp fmt e;
      List.iter (pp_exp fmt) el;
      let id = Hashtbl.find exp_map e in
      F.fprintf fmt.call "%a\t%s\n" Node.pp n id
  | Creturn (Some e, _) ->
      pp_exp fmt e;
      let id = Hashtbl.find exp_map e in
      F.fprintf fmt.return "%a\t%s\n" Node.pp n id
  | Cassume (e, _, _) ->
      pp_exp fmt e;
      let e_id = Hashtbl.find exp_map e in
      F.fprintf fmt.assume "%a\t%s\n" Node.pp n e_id
  | _ -> F.fprintf fmt.cmd "unknown"

let make_formatters dirname =
  let oc_func = open_out (dirname ^ "/Func.facts") in
  let oc_const = open_out (dirname ^ "/ConstExp.facts") in
  let oc_lval = open_out (dirname ^ "/LvalExp.facts") in
  let oc_binop = open_out (dirname ^ "/BinOpExp.facts") in
  let oc_unop = open_out (dirname ^ "/UnOpExp.facts") in
  let oc_cast = open_out (dirname ^ "/CastExp.facts") in
  let oc_exp = open_out (dirname ^ "/OtherExp.facts") in
  let oc_cmd = open_out (dirname ^ "/Cmd.facts") in
  let oc_entry = open_out (dirname ^ "/Entry.facts") in
  let oc_exit = open_out (dirname ^ "/Exit.facts") in
  let oc_skip = open_out (dirname ^ "/Skip.facts") in
  let oc_join = open_out (dirname ^ "/Join.facts") in
  let oc_assign = open_out (dirname ^ "/Assign.facts") in
  let oc_assume = open_out (dirname ^ "/Assume.facts") in
  let oc_alloc = open_out (dirname ^ "/Alloc.facts") in
  let oc_salloc = open_out (dirname ^ "/SAlloc.facts") in
  let oc_libcall = open_out (dirname ^ "/LibCall.facts") in
  let oc_call = open_out (dirname ^ "/Call.facts") in
  let oc_arg = open_out (dirname ^ "/Arg.facts") in
  let oc_return = open_out (dirname ^ "/Return.facts") in
  let oc_global_var = open_out (dirname ^ "/GlobalVar.facts") in
  let oc_local_var = open_out (dirname ^ "/LocalVar.facts") in
  let oc_field = open_out (dirname ^ "/Field.facts") in
  let oc_lv = open_out (dirname ^ "/Lval.facts") in
  let oc_mem = open_out (dirname ^ "/Mem.facts") in
  let oc_start_of = open_out (dirname ^ "/StartOf.facts") in
  (* BinOp *)
  let oc_plusa = open_out (dirname ^ "/PlusA.facts") in
  let oc_pluspi = open_out (dirname ^ "/PlusPI.facts") in
  let oc_indexpi = open_out (dirname ^ "/IndexPI.facts") in
  let oc_minusa = open_out (dirname ^ "/MinusA.facts") in
  let oc_minuspi = open_out (dirname ^ "/MinusPI.facts") in
  let oc_minuspp = open_out (dirname ^ "/MinusPP.facts") in
  let oc_mult = open_out (dirname ^ "/Mult.facts") in
  let oc_div = open_out (dirname ^ "/Div.facts") in
  let oc_modd = open_out (dirname ^ "/Mod.facts") in
  let oc_shiftlt = open_out (dirname ^ "/ShiftLt.facts") in
  let oc_shiftrt = open_out (dirname ^ "/ShiftRt.facts") in
  let oc_lt = open_out (dirname ^ "/Lt.facts") in
  let oc_gt = open_out (dirname ^ "/Gt.facts") in
  let oc_le = open_out (dirname ^ "/Le.facts") in
  let oc_ge = open_out (dirname ^ "/Ge.facts") in
  let oc_eq = open_out (dirname ^ "/Eq.facts") in
  let oc_ne = open_out (dirname ^ "/Ne.facts") in
  let oc_band = open_out (dirname ^ "/BAnd.facts") in
  let oc_bxor = open_out (dirname ^ "/BXor.facts") in
  let oc_bor = open_out (dirname ^ "/BOr.facts") in
  let oc_landd = open_out (dirname ^ "/LAnd.facts") in
  let oc_lorr = open_out (dirname ^ "/LOr.facts") in
  (* UnOp *)
  let oc_bnot = open_out (dirname ^ "/BNot.facts") in
  let oc_lnot = open_out (dirname ^ "/LNot.facts") in
  let oc_neg = open_out (dirname ^ "/Neg.facts") in
  let fmt =
    {
      func = F.formatter_of_out_channel oc_func;
      entry = F.formatter_of_out_channel oc_entry;
      exit = F.formatter_of_out_channel oc_exit;
      join = F.formatter_of_out_channel oc_join;
      skip = F.formatter_of_out_channel oc_skip;
      assign = F.formatter_of_out_channel oc_assign;
      assume = F.formatter_of_out_channel oc_assume;
      alloc = F.formatter_of_out_channel oc_alloc;
      salloc = F.formatter_of_out_channel oc_salloc;
      libcall = F.formatter_of_out_channel oc_libcall;
      call = F.formatter_of_out_channel oc_call;
      arg = F.formatter_of_out_channel oc_arg;
      return = F.formatter_of_out_channel oc_return;
      cmd = F.formatter_of_out_channel oc_cmd;
      const_exp = F.formatter_of_out_channel oc_const;
      lval_exp = F.formatter_of_out_channel oc_lval;
      binop_exp = F.formatter_of_out_channel oc_binop;
      unop_exp = F.formatter_of_out_channel oc_unop;
      cast_exp = F.formatter_of_out_channel oc_cast;
      other_exp = F.formatter_of_out_channel oc_exp;
      global_var = F.formatter_of_out_channel oc_global_var;
      local_var = F.formatter_of_out_channel oc_local_var;
      field = F.formatter_of_out_channel oc_field;
      lval = F.formatter_of_out_channel oc_lv;
      mem = F.formatter_of_out_channel oc_mem;
      start_of = F.formatter_of_out_channel oc_start_of;
      (* BinOp *)
      plusa = F.formatter_of_out_channel oc_plusa;
      pluspi = F.formatter_of_out_channel oc_pluspi;
      indexpi = F.formatter_of_out_channel oc_indexpi;
      minusa = F.formatter_of_out_channel oc_minusa;
      minuspi = F.formatter_of_out_channel oc_minuspi;
      minuspp = F.formatter_of_out_channel oc_minuspp;
      mult = F.formatter_of_out_channel oc_mult;
      div = F.formatter_of_out_channel oc_div;
      modd = F.formatter_of_out_channel oc_modd;
      shiftlt = F.formatter_of_out_channel oc_shiftlt;
      shiftrt = F.formatter_of_out_channel oc_shiftrt;
      lt = F.formatter_of_out_channel oc_lt;
      gt = F.formatter_of_out_channel oc_gt;
      le = F.formatter_of_out_channel oc_le;
      ge = F.formatter_of_out_channel oc_ge;
      eq = F.formatter_of_out_channel oc_eq;
      ne = F.formatter_of_out_channel oc_ne;
      band = F.formatter_of_out_channel oc_band;
      bxor = F.formatter_of_out_channel oc_bxor;
      bor = F.formatter_of_out_channel oc_bor;
      landd = F.formatter_of_out_channel oc_landd;
      lorr = F.formatter_of_out_channel oc_lorr;
      (* BinOp *)
      bnot = F.formatter_of_out_channel oc_bnot;
      lnot = F.formatter_of_out_channel oc_lnot;
      neg = F.formatter_of_out_channel oc_neg;
    }
  in
  let channels =
    [
      oc_func;
      oc_const;
      oc_lval;
      oc_binop;
      oc_cast;
      oc_exp;
      oc_cmd;
      oc_entry;
      oc_exit;
      oc_skip;
      oc_assign;
      oc_alloc;
      oc_salloc;
      oc_call;
      oc_libcall;
      oc_arg;
      oc_return;
      oc_global_var;
      oc_local_var;
      oc_field;
      oc_lv;
      oc_mem;
      oc_start_of;
    ]
  in
  (fmt, channels)

let close_formatters fmt channels =
  F.pp_print_flush fmt.func ();
  F.pp_print_flush fmt.entry ();
  F.pp_print_flush fmt.exit ();
  F.pp_print_flush fmt.skip ();
  F.pp_print_flush fmt.assign ();
  F.pp_print_flush fmt.alloc ();
  F.pp_print_flush fmt.salloc ();
  F.pp_print_flush fmt.call ();
  F.pp_print_flush fmt.libcall ();
  F.pp_print_flush fmt.arg ();
  F.pp_print_flush fmt.return ();
  F.pp_print_flush fmt.cmd ();
  F.pp_print_flush fmt.const_exp ();
  F.pp_print_flush fmt.lval_exp ();
  F.pp_print_flush fmt.binop_exp ();
  F.pp_print_flush fmt.unop_exp ();
  F.pp_print_flush fmt.cast_exp ();
  F.pp_print_flush fmt.other_exp ();
  F.pp_print_flush fmt.global_var ();
  F.pp_print_flush fmt.local_var ();
  F.pp_print_flush fmt.field ();
  F.pp_print_flush fmt.lval ();
  (* BinOp *)
  F.pp_print_flush fmt.plusa ();
  F.pp_print_flush fmt.pluspi ();
  F.pp_print_flush fmt.indexpi ();
  F.pp_print_flush fmt.minusa ();
  F.pp_print_flush fmt.minuspi ();
  F.pp_print_flush fmt.minuspp ();
  F.pp_print_flush fmt.mult ();
  F.pp_print_flush fmt.div ();
  F.pp_print_flush fmt.modd ();
  F.pp_print_flush fmt.shiftlt ();
  F.pp_print_flush fmt.shiftrt ();
  F.pp_print_flush fmt.lt ();
  F.pp_print_flush fmt.gt ();
  F.pp_print_flush fmt.le ();
  F.pp_print_flush fmt.ge ();
  F.pp_print_flush fmt.eq ();
  F.pp_print_flush fmt.ne ();
  F.pp_print_flush fmt.band ();
  F.pp_print_flush fmt.bxor ();
  F.pp_print_flush fmt.bor ();
  F.pp_print_flush fmt.landd ();
  F.pp_print_flush fmt.lorr ();
  (* UnOp *)
  F.pp_print_flush fmt.bnot ();
  F.pp_print_flush fmt.lnot ();
  F.pp_print_flush fmt.neg ();
  List.iter close_out channels

let print_relation dirname icfg =
  let fmt, channels = make_formatters dirname in
  List.iter (fun n -> pp_cmd fmt icfg n) (InterCfg.nodesof icfg);
  close_formatters fmt channels

let rec string_of_abstract_exp = function
  | Cil.Const _ -> "C"
  | Cil.Lval (Cil.Var v, _) when v.vstorage = Cil.Extern -> v.vname
  | Cil.Lval _ | Cil.StartOf _ -> "X"
  | Cil.BinOp (bop, e1, e2, _) ->
      string_of_abstract_exp e1 ^ CilHelper.s_bop bop
      ^ string_of_abstract_exp e2
  | Cil.UnOp (uop, e, _) -> CilHelper.s_uop uop ^ string_of_abstract_exp e
  | Cil.SizeOf _ | Cil.SizeOfE _ | Cil.SizeOfStr _ -> "SizeOf"
  | Cil.CastE (_, e) -> string_of_abstract_exp e
  | Cil.AddrOf _ -> "&X"
  | _ -> ""

let print_raw dirname =
  let oc_exp_json = open_out (dirname ^ "/Exp.json") in
  let oc_exp_text = open_out (dirname ^ "/Exp.map") in
  let text_fmt = F.formatter_of_out_channel oc_exp_text in
  let l =
    Hashtbl.fold
      (fun exp id l ->
        F.fprintf text_fmt "%s\t%s\n" id (CilHelper.s_exp exp);
        let json_exp = CilJson.of_exp exp in
        let exp =
          `Assoc
            [
              ("tree", json_exp);
              ("text", `String (CilHelper.s_exp exp));
              ("abs_text", `String (string_of_abstract_exp exp));
            ]
        in
        (id, exp) :: l)
      exp_map []
  in
  let json = `Assoc l in
  Yojson.Safe.to_channel oc_exp_json json;
  close_out oc_exp_json;
  close_out oc_exp_text

let print analysis icfg =
  Hashtbl.reset exp_map;
  Hashtbl.reset lv_map;
  Hashtbl.reset binop_map;
  let dirname = FileManager.analysis_dir analysis ^ "/datalog" in
  print_relation dirname icfg;
  print_raw dirname
