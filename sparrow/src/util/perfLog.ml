let action_names = Array.make 64 ""

let start_times = Array.make 64 0.0

let accum_times = Array.make 64 0.0

let reset_accum () = Array.fill accum_times 0 64 0.0

let register id name = action_names.(id) <- name

let start id = start_times.(id) <- Sys.time ()

let stop id =
  accum_times.(id) <- accum_times.(id) +. (Sys.time () -. start_times.(id))

let print_accum_time id =
  Printf.printf "Time for %s: %f sec\n" action_names.(id) accum_times.(id)

let sprint_accum_time id =
  Printf.sprintf "Time for %s: %f sec\n" action_names.(id) accum_times.(id)
