(* thunderbolt & sung *)

open Ast
open String
module StringHash = Hashtbl.Make(struct
	type t = string
	let equal x y = x = y
	let hash = Hashtbl.hash
	end)
module StringMap = Map.Make(String)

let translate (globals, functions) =
 let count = Array.make 1 0 in
 let global_var = StringHash.create 100 in
 let decl_global = StringHash.create 100 in
 let func = StringMap.empty in

 (**** Declare Global Variables ****)
 List.iter (fun (m, n) -> StringHash.add decl_global ((string_of_typ m) ^ ", " ^ n) "") globals;

 (* function declaration *)
 let function_decls = List.fold_left (fun m fd -> StringMap.add fd.fname fd m)
			 func functions

 in

 let main = StringMap.find "main" function_decls in

 (*let ptStr = ptStr ^ "#N canvas " ^ g ^ ";\r\n"*)
 let add s e = s ^ " " ^ (string_of_int e)

 in let ptStr = "#N canvas" ^ (List.fold_left add "" main.formals_opt) ^ ";\r\n"

 in

 (* count amount of objects *)
 let rec object_count funct =
	(* local variable declaration *)
	let decl_local = StringHash.create 100 in
	let local_var = StringHash.create 100 in

	(StringHash.add global_var "string, X" "#X");
 	(StringHash.add global_var "string, A" "#A");
	(StringHash.add global_var "string, N" "#N");
	List.iter (fun (m, n) ->
			StringHash.add decl_local ((string_of_typ m) ^ ", " ^ n) "") funct.locals;
 let rec expr_count = function
	  Literal n -> string_of_int n
	| BoolLit(true) -> "true"
	| BoolLit(false) -> "false"
	| Id s ->
		(if (StringHash.mem local_var ("int, " ^ s)) then
			(StringHash.find local_var ("int, " ^ s)) else
			(if (StringHash.mem local_var ("string, " ^ s)) then
				(StringHash.find local_var ("string, " ^ s)) else
				(if (StringHash.mem global_var ("int, " ^ s)) then
					(StringHash.find global_var ("int, " ^ s)) else
					(if (StringHash.mem global_var ("string, " ^ s)) then
						(StringHash.find global_var ("string, " ^ s)) else
						(StringHash.find local_var (""))
		))))
	| Str s -> let len = (String.length s) - 2 in
			String.sub s 1 len
	| Binop(e1, op, e2) -> let v1 = expr_count e1 and v2 = expr_count e2 in
		(match op with
			  Add -> string_of_int ((int_of_string v1) + (int_of_string v2))
			| Sub -> string_of_int ((int_of_string v1) - (int_of_string v2))
			| Mult -> string_of_int ((int_of_string v1) * (int_of_string v2))
			| Div -> string_of_int ((int_of_string v1) / (int_of_string v2))
			| Equal -> if (int_of_string v1) = (int_of_string v2)
					 then "true" else "false"
			| Neq -> if (int_of_string v1) != (int_of_string v2)
					then "true" else "false"
			| Less -> if (int_of_string v1) < (int_of_string v2)
					then "true" else "false"
			| Leq -> if (int_of_string v1) <= (int_of_string v2)
					then "true" else "false"
			| Greater -> if (int_of_string v1) > (int_of_string v2)
					then "true" else "false"
			| Geq -> if (int_of_string v1) >= (int_of_string v2)
					then "true" else "false"
			| And ->
				if v1 = "true" then
					(if v2 = "true" then "true" else "false")
				else "false"
			| Or -> (if v1 = "false" then
					(if v2 = "false" then "false" else "ture")
						else "true"))
	| Assign(s, e) -> let v = expr_count e in
		(if (StringHash.mem decl_local ("int, " ^ s)) then
			(StringHash.add local_var ("int, " ^ s) v) else
			(if (StringHash.mem decl_local ("string, " ^ s)) then
				(StringHash.add local_var ("string, " ^ s) v) else
				(if (StringHash.mem decl_global ("int, " ^ s)) then
					(StringHash.add global_var ("int, " ^ s) v) else
					(if (StringHash.mem decl_global ("string, " ^ s)) then
						(StringHash.add global_var ("string, " ^ s) v) else
						(StringHash.add local_var "" "") )))) ; ""
	| Unop(op, e) -> let v = expr_count e in
		(match op with
			  Neg -> string_of_int (0 - (int_of_string v))
			| Not -> if v = "true" then "false" else "true")
	| Noexpr -> ""
	| Call(fname, actuals) ->
		if fname != "connectW" || fname != "connectS" then
			(count.(0) <- (count.(0) + 1);
			ignore(if (StringMap.mem fname function_decls) then
			let internal = StringMap.find fname function_decls in
			count.(0) <- (count.(0) + 1); (object_count internal) else ""); "")
		else ""

 and

 stmt_count =
	let rec revStmt = function
	Block st -> List.rev st
	| Expr e -> ignore(expr_count e); []
	| If(p, b1, b2) -> (if (expr_count p) = "true" then (revStmt b1) else (revStmt b2))
	| For(e1, e2, e3, st) -> revStmt st
	| While(p, s) -> revStmt s
	in function
	Block st -> let rec check_block_count = function
				  Block sl :: ss ->  (check_block_count sl) ^ (check_block_count ss)
			 	| s :: ss -> (stmt_count s) ^ (check_block_count ss)
				| [] -> ""
				in check_block_count st
	| Expr e -> expr_count e
	| If(p, b1, b2) -> (if (expr_count p) = "true" then stmt_count (Block (revStmt b1))
				else stmt_count (Block (revStmt b2)))
	| For(e1, e2, e3, st) -> let sts = expr_count e1 in
					let rec loop sen =
						if (expr_count e2) = "true" then
			let tem = sen ^ stmt_count (Block (revStmt st)) ^ (expr_count e3) in
							loop tem
						else sen
					in loop sts
	| While(p, s) -> let rec loop sen =
				if (expr_count p) = "true" then
					let tem = sen ^ stmt_count (Block (revStmt s)) in
					loop tem
				else sen
			   in loop ""

 in
 ignore(stmt_count (Block funct.body)); string_of_int count.(0)

 in
 let obj = Array.make (int_of_string (object_count main)) "" in
 let global_vars = StringHash.create 100 in
 let i = Array.make 1 0 in

 (* saving object strings in array *)
 let rec create_local funct =
	(* local variable declaration *)
	let decl_local = StringHash.create 100 in
	let local_var = StringHash.create 100 in

	(StringHash.add global_vars "string, X" "#X");
 	(StringHash.add global_vars "string, A" "#A");
	(StringHash.add global_vars "string, N" "#N");
	List.iter (fun (m, n) ->
			StringHash.add decl_local ((string_of_typ m) ^ ", " ^ n) "") funct.locals;
 let rec expr = function
	  Literal n -> string_of_int n
	| BoolLit(true) -> "true"
	| BoolLit(false) -> "false"
	| Id s ->
		(if (StringHash.mem local_var ("int, " ^ s)) then
			(StringHash.find local_var ("int, " ^ s)) else
			(if (StringHash.mem local_var ("string, " ^ s)) then
				(StringHash.find local_var ("string, " ^ s)) else
				(if (StringHash.mem global_vars ("int, " ^ s)) then
					(StringHash.find global_vars ("int, " ^ s)) else
					(if (StringHash.mem global_vars ("string, " ^ s)) then
						(StringHash.find global_vars ("string, " ^ s)) else
				(StringHash.find local_var (""))
		))))
	| Str s -> let len = (String.length s) - 2 in
			String.sub s 1 len
	| Binop(e1, op, e2) -> let v1 = expr e1 and v2 = expr e2 in
		(match op with
			  Add -> string_of_int ((int_of_string v1) + (int_of_string v2))
			| Sub -> string_of_int ((int_of_string v1) - (int_of_string v2))
			| Mult -> string_of_int ((int_of_string v1) * (int_of_string v2))
			| Div -> string_of_int ((int_of_string v1) / (int_of_string v2))
			| Equal -> if (int_of_string v1) = (int_of_string v2)
					 then "true" else "false"
			| Neq -> if (int_of_string v1) != (int_of_string v2)
					then "true" else "false"
			| Less -> if (int_of_string v1) < (int_of_string v2)
					then "true" else "false"
			| Leq -> if (int_of_string v1) <= (int_of_string v2)
					then "true" else "false"
			| Greater -> if (int_of_string v1) > (int_of_string v2)
					then "true" else "false"
			| Geq -> if (int_of_string v1) >= (int_of_string v2)
					then "true" else "false"
			| And ->
				if v1 = "true" then
					(if v2 = "true" then "true" else "false")
				else "false"
			| Or -> (if v1 = "false" then
					(if v2 = "false" then "false" else "ture")
						else "true"))
	| Assign(s, e) -> let v = expr e in
		(if (StringHash.mem decl_local ("int, " ^ s)) then
			(StringHash.add local_var ("int, " ^ s) v) else
			(if (StringHash.mem decl_local ("string, " ^ s)) then
				(StringHash.add local_var ("string, " ^ s) v) else
				(if (StringHash.mem decl_global ("int, " ^ s)) then
					(StringHash.add global_vars ("int, " ^ s) v) else
					(if (StringHash.mem decl_global ("string, " ^ s)) then
						(StringHash.add global_vars ("string, " ^ s) v) else
						(StringHash.add local_var "" "") )))) ; ""
	| Unop(op, e) -> let v = expr e in
		(match op with
			  Neg -> string_of_int (0 - (int_of_string v))
			| Not -> if v = "true" then "false" else "true")
	| Noexpr -> ""
	| Call(fname, actuals) ->
		if fname != "connectW" || fname != "connectS" then
		let k = i.(0) in
		i.(0) <- (i.(0) + 1);
		(if fname = "object" then
			let a1 = List.hd actuals and a2 = List.tl actuals in
			let a2 = List.hd a2 and a3 = List.tl a2 in
			let a3 = List.hd a3 in
			let a1 = expr a1 and a2 = expr a2 and a3 = expr a3 in
			obj.(k) <- ("#X obj " ^ a2 ^ " " ^ a3 ^ " " ^ a1 ^ ";\r\n"); obj.(k) else
			(if (StringMap.mem fname function_decls) then
				let a1 = List.hd actuals and a2 = List.tl actuals in
				let a2 = List.hd a2 and a3 = List.tl a2 in
				let a3 = List.hd a3 in
				let a1 = expr a1 and a2 = expr a2 and a3 = expr a3 in
				let internal = StringMap.find fname function_decls in
				obj.(k) <- "#N canvas" ^ (List.fold_left add "" internal.formals_opt)
					^ " " ^ a1 ^ ";\r\n"; ignore(create_local internal);
				let k = i.(0) in
				i.(0) <- (i.(0) + 1);
				obj.(k) <- "#X restore " ^ a2 ^ " " ^ a3 ^ " " ^
					 "pd " ^ a1 ^ ";\r\n"; obj.(k)
			else
				(if fname = "kfi" then
				let a1 = List.hd actuals and a2 = List.tl actuals in
				let a1 = expr a1 and a2 = List.hd a2 in
				let a2 = expr a2 in
				obj.(k) <- (a1 ^ " " ^ a2 ^ ";\r\n"); obj.(k) else "")))
		else ""

 and

 stmt =
	let rec revStmt = function
	Block st -> List.rev st
	| Expr e -> ignore(expr e); []
	| If(p, b1, b2) -> (if (expr p) = "true" then (revStmt b1) else (revStmt b2))
	| For(e1, e2, e3, st) -> revStmt st
	| While(p, s) -> revStmt s
	in function
	Block st -> let rec check_block = function
				  Block sl :: ss ->  (check_block sl) ^ (check_block ss)
			 	| s :: ss -> (stmt s) ^ (check_block ss)
				| [] -> ""
				in check_block st
	| Expr e -> expr e
	| If(p, b1, b2) -> (if (expr p) = "true" then stmt (Block (revStmt b1))
				else stmt (Block (revStmt b2)))
	| For(e1, e2, e3, st) ->	let rec loop temp =
						if (expr e2) = "true" then
							(ignore(stmt (Block (revStmt st)));
							ignore(expr e3); loop "")
						else temp
					in loop (expr e1)
	| While(p, s) -> let rec loop temp =
				if (expr p) = "true" then
					(ignore(stmt (Block (revStmt s)));
					loop temp)
				else temp
			   in loop ""

 in
 (stmt (Block funct.body))

 in ignore(create_local main);

 let test = Array.to_list obj in
 let add_str s e = s ^ "" ^ e in

 ptStr ^ (List.fold_left add_str "" test)
