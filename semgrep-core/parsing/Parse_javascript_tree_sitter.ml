(* Yoann Padioleau
 *
 * Copyright (C) 2020 r2c
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License (GPL)
 * version 2 as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * file license.txt for more details.
 *)
open Common
module CST = Tree_sitter_javascript.CST
module AST = Ast_js
module H = Parse_tree_sitter_helpers
module G = AST_generic
open Ast_js

(*****************************************************************************)
(* Prelude *)
(*****************************************************************************)
(* Javascript parser using ocaml-tree-sitter-lang/javascript and converting
 * directly to pfff/lang_js/analyze/ast_js.ml
 *
 *)

(*****************************************************************************)
(* Helpers *)
(*****************************************************************************)

[@@@warning "-32"]

type env = H.env
let _fake = AST_generic.fake
let token = H.token
let str = H.str

let fb = G.fake_bracket

(*****************************************************************************)
(* Boilerplate converter *)
(*****************************************************************************)
(* This was started from ocaml-tree-sitter-lang/javascript/Boilerplate.ml *)

(**
   Boilerplate to be used as a template when mapping the javascript CST
   to another type of tree.
*)

(* Disable warnings against unused variables *)
[@@@warning "-26-27"]

(* Disable warning against unused 'rec' *)
[@@@warning "-39"]


let blank (env : env) () = ()

let todo (env : env) _ =
   failwith "not implemented"


let super env tok =
  IdSpecial (Super, token env tok)
let this env tok =
  IdSpecial (This, token env tok)
let empty_stmt env tok =
  let t = token env tok in
  Block (t, [], t)

let idexp id = Id (id, ref NotResolved)

let build_vars kwd vars =
  vars |> List.map (fun (id_or_pat, initopt) ->
      match id_or_pat with
      | Left id ->
      { v_name = id; v_kind = (Var, kwd); v_init = initopt;
        v_resolved = ref NotResolved }
      | Right pat ->
        raise Todo
   )

let stmt_of_stmts xs =
  match xs with
  | [] -> Block (fb [])
  | [x] -> x
  | xs -> Block (fb xs)


let identifier (env : env) (tok : CST.identifier) : ident =
  str env tok (* identifier *)

let identifier_exp (env : env) (tok : CST.identifier) : expr =
  let id = identifier env tok in
  idexp id

let reserved_identifier (env : env) (x : CST.reserved_identifier) : ident =
  (match x with
  | `Get tok -> identifier env tok (* "get" *)
  | `Set tok -> identifier env tok (* "set" *)
  | `Async tok -> identifier env tok (* "async" *)
  | `Static tok -> identifier env tok (* "static" *)
  )


let jsx_identifier (env : env) (tok : CST.jsx_identifier) =
  str env tok (* pattern [a-zA-Z_$][a-zA-Z\d_$]*-[a-zA-Z\d_$\-]* *)


let regex_pattern (env : env) (tok : CST.regex_pattern) =
  str env tok (* regex_pattern *)


let number (env : env) (tok : CST.number) =
  str env tok (* number *)

let escape_sequence (env : env) (tok : CST.escape_sequence) =
  str env tok (* escape_sequence *)



let regex_flags (env : env) (tok : CST.regex_flags) =
  str env tok (* pattern [a-z]+ *)

let anon_choice_PLUSPLUS (env : env) (x : CST.anon_choice_PLUSPLUS) =
  (match x with
  | `PLUSPLUS tok -> G.Incr, token env tok (* "++" *)
  | `DASHDASH tok -> G.Decr, token env tok (* "--" *)
  )

let template_chars (env : env) (tok : CST.template_chars) =
  str env tok (* template_chars *)


let jsx_text (env : env) (tok : CST.jsx_text) =
  str env tok (* pattern [^{}<>]+ *)

let automatic_semicolon (env : env) (tok : CST.automatic_semicolon) =
  token env tok (* automatic_semicolon *)

let namespace_import (env : env) ((v1, v2, v3) : CST.namespace_import) =
  let _v1 = token env v1 (* "*" *) in
  let _v2 = token env v2 (* "as" *) in
  let v3 = identifier env v3 (* identifier *) in
  v3

let rec nested_identifier (env : env) ((v1, v2, v3) : CST.nested_identifier) : ident list =
  let v1 =
    (match v1 with
    | `Id tok -> [identifier env tok] (* identifier *)
    | `Nested_id x -> nested_identifier env x
    )
  in
  let _v2 = token env v2 (* "." *) in
  let v3 = identifier env v3 (* identifier *) in
  v1 @ [ v3]

let import_export_specifier (env : env) ((v1, v2) : CST.import_export_specifier) =
  let v1 = identifier env v1 (* identifier *) in
  let v2 =
    (match v2 with
    | Some (v1, v2) ->
        let _v1 = token env v1 (* "as" *) in
        let v2 = identifier env v2 (* identifier *) in
        Some v2
    | None -> None)
  in
  (v1, v2)

let anon_choice_blank (env : env) (x : CST.anon_choice_blank) =
  (match x with
  | `Blank () -> None
  | `Esc_seq tok -> Some (str env tok) (* escape_sequence *)
  )

let anon_choice_rese_id (env : env) (x : CST.anon_choice_rese_id) : ident =
  (match x with
  | `Choice_get x -> reserved_identifier env x
  | `Id tok -> identifier env tok (* identifier *)
  )

let identifier_reference (env : env) (x : CST.identifier_reference) : ident =
  (match x with
  | `Id tok -> identifier env tok (* identifier *)
  | `Choice_get x -> reserved_identifier env x
  )

let jsx_identifier_ (env : env) (x : CST.jsx_identifier_) =
  (match x with
  | `Jsx_id tok ->
      str env tok (* pattern [a-zA-Z_$][a-zA-Z\d_$]*-[a-zA-Z\d_$\-]* *)
  | `Id tok -> identifier env tok (* identifier *)
  )

let semicolon (env : env) (x : CST.semicolon) =
  (match x with
  | `Auto_semi tok -> automatic_semicolon env tok (* automatic_semicolon *)
  | `SEMI tok -> token env tok (* ";" *)
  )

let anon_import_export_spec_rep_COMMA_import_export_spec (env : env) ((v1, v2) : CST.anon_import_export_spec_rep_COMMA_import_export_spec) =
  let v1 = import_export_specifier env v1 in
  let v2 =
    List.map (fun (v1, v2) ->
      let _v1 = token env v1 (* "," *) in
      let v2 = import_export_specifier env v2 in
      v2
    ) v2
  in
  v1::v2

let string_ (env : env) (x : CST.string_) : string wrap =
  (match x with
  | `DQUOT_rep_choice_blank_DQUOT (v1, v2, v3) ->
      let v1 = token env v1 (* "\"" *) in
      let v2 = Common.map_filter (anon_choice_blank env) v2 in
      let v3 = token env v3 (* "\"" *) in
      let str = v2 |> List.map fst |> String.concat "" in
      let toks = [v1] @ (v2 |> List.map snd) @ [v3] in
      str, H.combine_infos env toks
  | `SQUOT_rep_choice_blank_SQUOT (v1, v2, v3) ->
      let v1 = token env v1 (* "'" *) in
      let v2 = Common.map_filter (anon_choice_blank env) v2 in
      let v3 = token env v3 (* "'" *) in
      let str = v2 |> List.map fst |> String.concat "" in
      let toks = [v1] @ (v2 |> List.map snd) @ [v3] in
      str, H.combine_infos env toks
  )

let rec decorator_member_expression (env : env) ((v1, v2, v3) : CST.decorator_member_expression) : ident list =
  let v1 = anon_choice_id_ref env v1 in
  let _v2 = token env v2 (* "." *) in
  let v3 = identifier env v3 (* identifier *) in
  v1 @ [v3]

and anon_choice_id_ref (env : env) (x : CST.anon_choice_id_ref) : ident list =
  (match x with
  | `Choice_id x -> [identifier_reference env x]
  | `Deco_member_exp x ->
      decorator_member_expression env x
  )

let jsx_namespace_name (env : env) ((v1, v2, v3) : CST.jsx_namespace_name) =
  let v1 = jsx_identifier_ env v1 in
  let _v2 = token env v2 (* ":" *) in
  let v3 = jsx_identifier_ env v3 in
  v1, v3

let export_clause (env : env) ((v1, v2, v3, v4) : CST.export_clause) =
  let _v1 = token env v1 (* "{" *) in
  let v2 =
    (match v2 with
    | Some x ->
        anon_import_export_spec_rep_COMMA_import_export_spec env x
    | None -> [])
  in
  let _v3 =
    (match v3 with
    | Some tok -> Some (token env tok) (* "," *)
    | None -> None)
  in
  let _v4 = token env v4 (* "}" *) in
  v2

let named_imports (env : env) ((v1, v2, v3, v4) : CST.named_imports) =
  let _v1 = token env v1 (* "{" *) in
  let v2 =
    (match v2 with
    | Some x ->
        anon_import_export_spec_rep_COMMA_import_export_spec env x
    | None -> [])
  in
  let _v3 =
    (match v3 with
    | Some tok -> Some (token env tok) (* "," *)
    | None -> None)
  in
  let _v4 = token env v4 (* "}" *) in
  v2

let from_clause (env : env) ((v1, v2) : CST.from_clause) =
  let _v1 = token env v1 (* "from" *) in
  let v2 = string_ env v2 in
  v2

let jsx_attribute_name (env : env) (x : CST.jsx_attribute_name) =
  (match x with
  | `Choice_jsx_id x ->
        jsx_identifier_ env x
  | `Jsx_name_name x ->
        let (id1, id2) = jsx_namespace_name env x in
        let str = fst id1 ^ ":" ^ fst id2 in
        str, H.combine_infos env [snd id1; snd id2]
  )

let jsx_element_name (env : env) (x : CST.jsx_element_name) : ident =
  (match x with
  | `Choice_jsx_id x -> jsx_identifier_ env x
  | `Nested_id x ->
        let xs = nested_identifier env x in
        let str = xs |> List.map fst |> String.concat "." in
        str, H.combine_infos env (xs |> List.map snd)
  | `Jsx_name_name x ->
        let (id1, id2) = jsx_namespace_name env x in
        let str = fst id1 ^ ":" ^ fst id2 in
        str, H.combine_infos env [snd id1; snd id2]
  )

let import_clause (env : env) (x : CST.import_clause) =
  (match x with
  | `Name_import x -> namespace_import env x
  | `Named_imports x ->
        let aliases = named_imports env x in
        todo env aliases
  | `Id_opt_COMMA_choice_name_import (v1, v2) ->
      let v1 = identifier env v1 (* identifier *) in
      let v2 =
        (match v2 with
        | Some (v1, v2) ->
            let _v1 = token env v1 (* "," *) in
            let v2 =
              (match v2 with
              | `Name_import x -> namespace_import env x
              | `Named_imports x ->
                        let aliases = named_imports env x in
                        todo env aliases
              )
            in
            v2
        | None -> todo env ())
      in
      todo env (v1, v2)
  )

let jsx_closing_element (env : env) ((v1, v2, v3, v4) : CST.jsx_closing_element) =
  let _v1 = token env v1 (* "<" *) in
  let _v2 = token env v2 (* "/" *) in
  let v3 = jsx_element_name env v3 in
  let _v4 = token env v4 (* ">" *) in
  v3

let rec parenthesized_expression (env : env) ((v1, v2, v3) : CST.parenthesized_expression) =
  let _v1 = token env v1 (* "(" *) in
  let v2 = expressions env v2 in
  let _v3 = token env v3 (* ")" *) in
  v2

and jsx_opening_element (env : env) ((v1, v2, v3, v4) : CST.jsx_opening_element) =
  let _v1 = token env v1 (* "<" *) in
  let v2 = jsx_element_name env v2 in
  let v3 = List.map (jsx_attribute_ env) v3 in
  let _v4 = token env v4 (* ">" *) in
  v2, v3

and destructuring_pattern (env : env) (x : CST.destructuring_pattern) : pattern =
  (match x with
  | `Obj x ->
        let o = object_ env x in
        Obj o
  | `Array x -> array_ env x
  )

and variable_declaration (env : env) ((v1, v2, v3, v4) : CST.variable_declaration) : var list =
  let v1 = token env v1 (* "var" *) in
  let v2 = variable_declarator env v2 in
  let v3 =
    List.map (fun (v1, v2) ->
      let _v1 = token env v1 (* "," *) in
      let v2 = variable_declarator env v2 in
      v2
    ) v3
  in
  let _v4 = semicolon env v4 in
  let vars = v2::v3 in
  build_vars v1 vars

and function_ (env : env) ((v1, v2, v3, v4, v5) : CST.function_) : fun_ * ident option =
  let v1 =
    (match v1 with
    | Some tok -> [Async, token env tok] (* "async" *)
    | None -> [])
  in
  let _v2 = token env v2 (* "function" *) in
  let v3 =
    (match v3 with
    | Some tok -> Some (identifier env tok) (* identifier *)
    | None -> None)
  in
  let v4 = formal_parameters env v4 in
  let v5 = statement_block env v5 in
  { f_props = v1; f_params = v4; f_body = v5 }, v3

and anon_choice_exp (env : env) (x : CST.anon_choice_exp) =
  (match x with
  | `Exp x -> expression env x
  | `Spread_elem x ->
        let (t, e) = spread_element env x in
        Apply (IdSpecial (Spread, t), fb [e])
  )

and binary_expression (env : env) (x : CST.binary_expression) : expr =
  (match x with
  | `Exp_AMPAMP_exp (v1, v2, v3) ->
      let v1 = expression env v1 in
      let v2 = token env v2 (* "&&" *) in
      let v3 = expression env v3 in
      Apply (IdSpecial (ArithOp G.And, v2), fb [v1; v3])
  | `Exp_BARBAR_exp (v1, v2, v3) ->
      let v1 = expression env v1 in
      let v2 = token env v2 (* "||" *) in
      let v3 = expression env v3 in
      Apply (IdSpecial (ArithOp G.Or, v2), fb [v1; v3])
  | `Exp_GTGT_exp (v1, v2, v3) ->
      let v1 = expression env v1 in
      let v2 = token env v2 (* ">>" *) in
      let v3 = expression env v3 in
      Apply (IdSpecial (ArithOp G.LSR, v2), fb [v1; v3])
  | `Exp_GTGTGT_exp (v1, v2, v3) ->
      let v1 = expression env v1 in
      let v2 = token env v2 (* ">>>" *) in
      let v3 = expression env v3 in
      Apply (IdSpecial (ArithOp G.ASR, v2), fb [v1; v3])
  | `Exp_LTLT_exp (v1, v2, v3) ->
      let v1 = expression env v1 in
      let v2 = token env v2 (* "<<" *) in
      let v3 = expression env v3 in
      Apply (IdSpecial (ArithOp G.LSL, v2), fb [v1; v3])
  | `Exp_AMP_exp (v1, v2, v3) ->
      let v1 = expression env v1 in
      let v2 = token env v2 (* "&" *) in
      let v3 = expression env v3 in
      Apply (IdSpecial (ArithOp G.BitAnd, v2), fb [v1; v3])
  | `Exp_HAT_exp (v1, v2, v3) ->
      let v1 = expression env v1 in
      let v2 = token env v2 (* "^" *) in
      let v3 = expression env v3 in
      Apply (IdSpecial (ArithOp G.BitXor, v2), fb [v1; v3])
  | `Exp_BAR_exp (v1, v2, v3) ->
      let v1 = expression env v1 in
      let v2 = token env v2 (* "|" *) in
      let v3 = expression env v3 in
      Apply (IdSpecial (ArithOp G.BitOr, v2), fb [v1; v3])
  | `Exp_PLUS_exp (v1, v2, v3) ->
      let v1 = expression env v1 in
      let v2 = token env v2 (* "+" *) in
      let v3 = expression env v3 in
      Apply (IdSpecial (ArithOp G.Plus, v2), fb [v1; v3])
  | `Exp_DASH_exp (v1, v2, v3) ->
      let v1 = expression env v1 in
      let v2 = token env v2 (* "-" *) in
      let v3 = expression env v3 in
      Apply (IdSpecial (ArithOp G.Minus, v2), fb [v1; v3])
  | `Exp_STAR_exp (v1, v2, v3) ->
      let v1 = expression env v1 in
      let v2 = token env v2 (* "*" *) in
      let v3 = expression env v3 in
      Apply (IdSpecial (ArithOp G.Mult, v2), fb [v1; v3])
  | `Exp_SLASH_exp (v1, v2, v3) ->
      let v1 = expression env v1 in
      let v2 = token env v2 (* "/" *) in
      let v3 = expression env v3 in
      Apply (IdSpecial (ArithOp G.Div, v2), fb [v1; v3])
  | `Exp_PERC_exp (v1, v2, v3) ->
      let v1 = expression env v1 in
      let v2 = token env v2 (* "%" *) in
      let v3 = expression env v3 in
      Apply (IdSpecial (ArithOp G.Mod, v2), fb [v1; v3])
  | `Exp_STARSTAR_exp (v1, v2, v3) ->
      let v1 = expression env v1 in
      let v2 = token env v2 (* "**" *) in
      let v3 = expression env v3 in
      Apply (IdSpecial (ArithOp G.Pow, v2), fb [v1; v3])
  | `Exp_LT_exp (v1, v2, v3) ->
      let v1 = expression env v1 in
      let v2 = token env v2 (* "<" *) in
      let v3 = expression env v3 in
      Apply (IdSpecial (ArithOp G.Lt, v2), fb [v1; v3])
  | `Exp_LTEQ_exp (v1, v2, v3) ->
      let v1 = expression env v1 in
      let v2 = token env v2 (* "<=" *) in
      let v3 = expression env v3 in
      Apply (IdSpecial (ArithOp G.LtE, v2), fb [v1; v3])
  | `Exp_EQEQ_exp (v1, v2, v3) ->
      let v1 = expression env v1 in
      let v2 = token env v2 (* "==" *) in
      let v3 = expression env v3 in
      Apply (IdSpecial (ArithOp G.Eq, v2), fb [v1; v3])
  | `Exp_EQEQEQ_exp (v1, v2, v3) ->
      let v1 = expression env v1 in
      let v2 = token env v2 (* "===" *) in
      let v3 = expression env v3 in
      Apply (IdSpecial (ArithOp G.PhysEq, v2), fb [v1; v3])
  | `Exp_BANGEQ_exp (v1, v2, v3) ->
      let v1 = expression env v1 in
      let v2 = token env v2 (* "!=" *) in
      let v3 = expression env v3 in
      Apply (IdSpecial (ArithOp G.NotEq, v2), fb [v1; v3])
  | `Exp_BANGEQEQ_exp (v1, v2, v3) ->
      let v1 = expression env v1 in
      let v2 = token env v2 (* "!==" *) in
      let v3 = expression env v3 in
      Apply (IdSpecial (ArithOp G.NotPhysEq, v2), fb [v1; v3])
  | `Exp_GTEQ_exp (v1, v2, v3) ->
      let v1 = expression env v1 in
      let v2 = token env v2 (* ">=" *) in
      let v3 = expression env v3 in
      Apply (IdSpecial (ArithOp G.GtE, v2), fb [v1; v3])
  | `Exp_GT_exp (v1, v2, v3) ->
      let v1 = expression env v1 in
      let v2 = token env v2 (* ">" *) in
      let v3 = expression env v3 in
      Apply (IdSpecial (ArithOp G.Gt, v2), fb [v1; v3])

  (* TODO *)
  | `Exp_QMARKQMARK_exp (v1, v2, v3) ->
      let v1 = expression env v1 in
      let v2 = token env v2 (* "??" *) in
      let v3 = expression env v3 in
      todo env (v1, v2, v3)

  | `Exp_inst_exp (v1, v2, v3) ->
      let v1 = expression env v1 in
      let v2 = token env v2 (* "instanceof" *) in
      let v3 = expression env v3 in
      Apply (IdSpecial (Instanceof, v2), fb [v1; v3])
  | `Exp_in_exp (v1, v2, v3) ->
      let v1 = expression env v1 in
      let v2 = token env v2 (* "in" *) in
      let v3 = expression env v3 in
      Apply (IdSpecial (In, v2), fb [v1; v3])

  )

and arguments (env : env) ((v1, v2, v3) : CST.arguments) : arguments =
  let v1 = token env v1 (* "(" *) in
  let v2 =
    anon_opt_opt_choice_exp_rep_COMMA_opt_choice_exp env v2
  in
  let v3 = token env v3 (* ")" *) in
  v1, v2, v3

and variable_declarator (env : env) ((v1, v2) : CST.variable_declarator) =
  let v1 = anon_choice_id env v1 in
  let v2 =
    (match v2 with
    | Some x -> Some (initializer_ env x)
    | None -> None)
  in
  v1, v2

and sequence_expression (env : env) ((v1, v2, v3) : CST.sequence_expression) =
  let v1 = expression env v1 in
  let v2 = token env v2 (* "," *) in
  let v3 =
    (match v3 with
    | `Seq_exp x -> sequence_expression env x
    | `Exp x -> expression env x
    )
  in
  Apply (IdSpecial (Seq, v2), fb [v1; v3])

and jsx_fragment (env : env) ((v1, v2, v3, v4, v5, v6) : CST.jsx_fragment)
 : xml =
  let v1 = token env v1 (* "<" *) in
  let _v2 = token env v2 (* ">" *) in
  let v3 = List.map (jsx_child env) v3 in
  let _v4 = token env v4 (* "<" *) in
  let _v5 = token env v5 (* "/" *) in
  let _v6 = token env v6 (* ">" *) in
  { xml_tag = "", v1; xml_attrs = []; xml_body = v3 }

and class_body (env : env) ((v1, v2, v3) : CST.class_body) =
  let v1 = token env v1 (* "{" *) in
  let v2 =
    List.map (fun x ->
      (match x with
      | `Meth_defi_opt_SEMI (v1, v2) ->
          let v1 = method_definition env v1 in
          let _v2 =
            (match v2 with
            | Some tok -> Some (token env tok) (* ";" *)
            | None -> None)
          in
          v1
      | `Public_field_defi_choice_auto_semi (v1, v2) ->
          let v1 = public_field_definition env v1 in
          let _v2 = semicolon env v2 in
          v1
      )
    ) v2
  in
  let v3 = token env v3 (* "}" *) in
  v1, v2, v3

and member_expression (env : env) ((v1, v2, v3) : CST.member_expression) : expr =
  let v1 =
    (match v1 with
    | `Exp x -> expression env x
    | `Id tok ->
          identifier_exp env tok (* identifier *)
    | `Super tok -> super env tok (* "super" *)
    | `Choice_get x ->
          let id = reserved_identifier env x in
          idexp id
    )
  in
  let v2 = token env v2 (* "." *) in
  let v3 = identifier env v3 (* identifier *) in
  ObjAccess (v1, v2, PN v3)

and assignment_pattern (env : env) ((v1, v2, v3) : CST.assignment_pattern) =
  let v1 =
    (match v1 with
    | `Choice_choice_get x ->
          let id = anon_choice_rese_id env x in
          idexp id
    | `Choice_obj x -> destructuring_pattern env x
    )
  in
  let v2 = token env v2 (* "=" *) in
  let v3 = expression env v3 in
  Assign (v1, v2, v3)

and jsx_expression (env : env) ((v1, v2, v3) : CST.jsx_expression) : expr =
  let v1 = token env v1 (* "{" *) in
  let v2 =
    (match v2 with
    | Some x ->
        (match x with
        | `Exp x -> expression env x
        | `Seq_exp x -> sequence_expression env x
        | `Spread_elem x ->
                let (t, e) = spread_element env x in
                Apply (IdSpecial (Spread, t), fb [e])
        )
    (* ?? TODO *)
    | None -> IdSpecial (Null, v1))
  in
  let _v3 = token env v3 (* "}" *) in
  v2

and anon_choice_pair (env : env) (x : CST.anon_choice_pair) : property =
  (match x with
  | `Pair (v1, v2, v3) ->
      let v1 = property_name env v1 in
      let _v2 = token env v2 (* ":" *) in
      let v3 = expression env v3 in
      Field (v1, [], Some v3)
  | `Spread_elem x ->
        let (t, e) = spread_element env x in
        FieldSpread (t, e)
  | `Meth_defi x -> method_definition env x
  | `Assign_pat x ->
        let e = assignment_pattern env x in
        todo env e
  (* ?? TODO *)
  | `Choice_id x ->
        let id = identifier_reference env x in
        todo env id
  )

and subscript_expression (env : env) ((v1, v2, v3, v4) : CST.subscript_expression) : expr =
  let v1 =
    (match v1 with
    | `Exp x -> expression env x
    | `Super tok -> super env tok (* "super" *)
    )
  in
  let _v2 = token env v2 (* "[" *) in
  let v3 = expressions env v3 in
  let _v4 = token env v4 (* "]" *) in
  ArrAccess (v1, v3)

and initializer_ (env : env) ((v1, v2) : CST.initializer_) =
  let v1 = token env v1 (* "=" *) in
  let v2 = expression env v2 in
  v2

and constructable_expression (env : env) (x : CST.constructable_expression) : expr =
  (match x with
  | `This tok -> this env tok (* "this" *)
  | `Id tok -> identifier_exp env tok (* identifier *)
  | `Choice_get x ->
        let id = reserved_identifier env x in
        idexp id
  | `Num tok ->
        let n = number env tok (* number *) in
        Num n
  | `Str x ->
        let s = string_ env x in
        String s
  | `Temp_str x -> template_string env x
  | `Regex (v1, v2, v3, v4) ->
      let v1 = token env v1 (* "/" *) in
      let (s, t) = str env v2 (* regex_pattern *) in
      let v3 = token env v3 (* "/" *) in
      let v4 =
        (match v4 with
        | Some tok -> [token env tok] (* pattern [a-z]+ *)
        | None -> [])
      in
      let tok = H.combine_infos env ([v1; t; v3] @ v4) in
      Regexp (s, t)
  | `True tok -> Bool (true, token env tok) (* "true" *)
  | `False tok -> Bool (false, token env tok) (* "false" *)
  | `Null tok -> IdSpecial (Null, token env tok) (* "null" *)
  | `Unde tok -> IdSpecial (Undefined, token env tok) (* "undefined" *)
  (* ?? *)
  | `Import tok -> let id = identifier env tok (* import *) in
          idexp id

  | `Obj x -> let o = object_ env x in Obj o
  | `Array x -> array_ env x
  | `Func x ->
        let f, idopt = function_ env x in
        Fun (f, idopt)
  | `Arrow_func (v1, v2, v3, v4) ->
      let v1 =
        (match v1 with
        | Some tok -> [Async, token env tok] (* "async" *)
        | None -> [])
      in
      let v2 =
        (match v2 with
        | `Choice_choice_get x ->
                let id = anon_choice_rese_id env x in
                [ParamClassic { p_name = id; p_default = None; p_dots = None}]
        | `Formal_params x -> call_signature env x
        )
      in
      let v3 = token env v3 (* "=>" *) in
      let v4 =
        (match v4 with
        | `Exp x ->
                let e = expression env x in
                Return (v3, Some e)
        | `Stmt_blk x -> statement_block env x
        )
      in
      let f = { f_props = v1; f_params = v2; f_body = v4 } in
      Fun (f, None)
  | `Gene_func (v1, v2, v3, v4, v5, v6) ->
      let v1 =
        (match v1 with
        | Some tok -> [Async, token env tok] (* "async" *)
        | None -> [])
      in
      let v2 = token env v2 (* "function" *) in
      let v3 = [Generator, token env v3] (* "*" *) in
      let v4 =
        (match v4 with
        | Some tok -> Some (identifier env tok) (* identifier *)
        | None -> None)
      in
      let v5 = formal_parameters env v5 in
      let v6 = statement_block env v6 in
      let f = { f_props = v1@v3; f_params = v5; f_body = v6 } in
      Fun (f, v4)
  | `Class (v1, v2, v3, v4, v5) ->
      let _v1TODO = List.map (decorator env) v1 in
      let v2 = token env v2 (* "class" *) in
      let v3 =
        (match v3 with
        | Some tok -> Some (identifier env tok) (* identifier *)
        | None -> None)
      in
      let v4 =
        (match v4 with
        | Some x -> Some (class_heritage env x)
        | None -> None)
      in
      let v5 = class_body env v5 in
      let class_ = { c_tok = v2;  c_extends = v4; c_body = v5 } in
      Class (class_, v3)
  | `Paren_exp x -> parenthesized_expression env x
  | `Subs_exp x -> subscript_expression env x
  | `Member_exp x -> member_expression env x
  | `Meta_prop (v1, v2, v3) ->
      let v1 = token env v1 (* "new" *) in
      let v2 = token env v2 (* "." *) in
      let v3 = token env v3 (* "target" *) in
      let t = H.combine_infos env [v1;v2;v3] in
      IdSpecial (NewTarget, t)
  | `New_exp (v1, v2, v3) ->
      let v1 = token env v1 (* "new" *) in
      let v2 = constructable_expression env v2 in
      let (t1, xs, t2) =
        (match v3 with
        | Some x -> arguments env x
        | None -> fb [])
      in
      Apply (IdSpecial (New, v1), (t1, v2::xs, t2))
  )

and jsx_attribute_ (env : env) (x : CST.jsx_attribute_) =
  (match x with
  | `Jsx_attr (v1, v2) ->
      let v1 = jsx_attribute_name env v1 in
      let v2 =
        (match v2 with
        | Some (v1, v2) ->
            let _v1bis = token env v1 (* "=" *) in
            let v2 = jsx_attribute_value env v2 in
            (v1, v2)
         (* ?? TODO *)
        | None -> todo env ())
      in
      v2
  (* ?? TODO *)
  | `Jsx_exp x ->
        let e = jsx_expression env x in
        todo env e
  )

and expression_statement (env : env) ((v1, v2) : CST.expression_statement) =
  let v1 = expressions env v1 in
  let v2 = semicolon env v2 in
  ExprStmt (v1, v2)

and catch_clause (env : env) ((v1, v2, v3) : CST.catch_clause) =
  let v1 = token env v1 (* "catch" *) in
  let v3 = statement_block env v3 in
  let v2 =
    (match v2 with
    | Some (v1bis, v2, v3bis) ->
        let _v1 = token env v1bis (* "(" *) in
        let v2 = anon_choice_id env v2 in
        let _v3 = token env v3bis (* ")" *) in
        let pat =
          match v2 with
          | Left id -> idexp id
          | Right pat -> pat
         in
        BoundCatch (v1, pat, v3)
    | None -> UnboundCatch (v1, v3))
  in
  v2

and template_string (env : env) ((v1, v2, v3) : CST.template_string) =
  let v1 = token env v1 (* "`" *) in
  let v2 =
    List.map (fun x ->
      (match x with
      | `Temp_chars tok -> token env tok (* template_chars *)
      | `Esc_seq tok -> token env tok (* escape_sequence *)
      | `Temp_subs x -> template_substitution env x
      )
    ) v2
  in
  let v3 = token env v3 (* "`" *) in
  todo env (v1, v2, v3)

and decorator (env : env) ((v1, v2) : CST.decorator) =
  let v1 = token env v1 (* "@" *) in
  let v2 =
    (match v2 with
    | `Choice_id x ->
          let id = identifier_reference env x in
          [id], None

    | `Deco_member_exp x ->
          let ids = decorator_member_expression env x in
          ids, None
    | `Deco_call_exp x ->
          let ids, args = decorator_call_expression env x in
          ids, Some args
    )
  in
  v1, v2

and anon_opt_opt_choice_exp_rep_COMMA_opt_choice_exp (env : env) (opt : CST.anon_opt_opt_choice_exp_rep_COMMA_opt_choice_exp) =
  (match opt with
  | Some (v1, v2) ->
      let v1 =
        (match v1 with
        | Some x -> anon_choice_exp env x
        | None -> todo env ())
      in
      let v2 = anon_rep_COMMA_opt_choice_exp env v2 in
      todo env (v1, v2)
  | None -> todo env ())

and for_header (env : env) ((v1, v2, v3, v4, v5, v6) : CST.for_header) =
  let v1 = token env v1 (* "(" *) in
  let v2 =
    (match v2 with
    | Some x ->
        (match x with
        | `Var tok -> token env tok (* "var" *)
        | `Let tok -> token env tok (* "let" *)
        | `Const tok -> token env tok (* "const" *)
        )
    | None -> todo env ())
  in
  let v3 = anon_choice_paren_exp env v3 in
  let v4 =
    (match v4 with
    | `In tok -> token env tok (* "in" *)
    | `Of tok -> token env tok (* "of" *)
    )
  in
  let v5 = expressions env v5 in
  let v6 = token env v6 (* ")" *) in
  todo env (v1, v2, v3, v4, v5, v6)

and expression (env : env) (x : CST.expression) : expr =
  (match x with
  | `Choice_this x -> constructable_expression env x
  | `Choice_jsx_elem x ->
        let xml = jsx_element_ env x in
        Xml xml
  | `Jsx_frag x ->
        let xml = jsx_fragment env x in
        Xml xml
  | `Assign_exp (v1, v2, v3) ->
      let v1 = anon_choice_paren_exp env v1 in
      let v2 = token env v2 (* "=" *) in
      let v3 = expression env v3 in
      Assign (v1, v2, v3)
  | `Augm_assign_exp (v1, v2, v3) ->
      let v1 =
        (match v1 with
        | `Member_exp x -> member_expression env x
        | `Subs_exp x -> subscript_expression env x
        | `Choice_get x ->
                let id = reserved_identifier env x in
                idexp id
        | `Id tok ->
                let id = identifier env tok (* identifier *) in
                idexp id
        | `Paren_exp x -> parenthesized_expression env x
        )
      in
      let (op, tok) =
        (match v2 with
        | `PLUSEQ tok -> G.Plus, token env tok (* "+=" *)
        | `DASHEQ tok -> G.Minus, token env tok (* "-=" *)
        | `STAREQ tok -> G.Mult, token env tok (* "*=" *)
        | `SLASHEQ tok -> G.Div, token env tok (* "/=" *)
        | `PERCEQ tok -> G.Mod, token env tok (* "%=" *)
        | `HATEQ tok -> G.BitXor, token env tok (* "^=" *)
        | `AMPEQ tok -> G.BitAnd, token env tok (* "&=" *)
        | `BAREQ tok -> G.BitOr, token env tok (* "|=" *)
        | `GTGTEQ tok -> G.LSR, token env tok (* ">>=" *)
        | `GTGTGTEQ tok -> G.ASR, token env tok (* ">>>=" *)
        | `LTLTEQ tok -> G.LSL, token env tok (* "<<=" *)
        | `STARSTAREQ tok -> G.Pow, token env tok (* "**=" *)
        )
      in
      let v3 = expression env v3 in
      (* todo: should use intermediate instead of repeating v1 *)
      Assign (v1, tok, Apply (IdSpecial (ArithOp op, tok), fb [v1;v3]))
  | `Await_exp (v1, v2) ->
      let v1 = token env v1 (* "await" *) in
      let v2 = expression env v2 in
      Apply (IdSpecial (Await, v1), fb [v2])
  | `Un_exp x -> unary_expression env x
  | `Bin_exp x -> binary_expression env x
  | `Tern_exp (v1, v2, v3, v4, v5) ->
      let v1 = expression env v1 in
      let _v2 = token env v2 (* "?" *) in
      let v3 = expression env v3 in
      let _v4 = token env v4 (* ":" *) in
      let v5 = expression env v5 in
      Conditional (v1, v3, v5)
  | `Update_exp x -> update_expression env x
  | `Call_exp (v1, v2) ->
      let v1 =
        (match v1 with
        | `Exp x -> expression env x
        | `Super tok -> super env tok (* "super" *)
        | `Func x ->
                let (f, idopt) = function_ env x in
                Fun (f, idopt)
        )
      in
      let v2 =
        (match v2 with
        | `Args x ->
                let args = arguments env x in
                args
        | `Temp_str x ->
                let x = template_string env x in
                todo env x
        )
      in
      Apply (v1, v2)
  | `Yield_exp (v1, v2) ->
      let v1 = token env v1 (* "yield" *) in
      let v2 =
        (match v2 with
        | `STAR_exp (v1bis, v2) ->
            let v1bis = token env v1bis (* "*" *) in
            let v2 = expression env v2 in
            Apply (IdSpecial (YieldStar, v1), fb [v2])
        | `Opt_exp opt ->
            (match opt with
            | Some x ->
                let x = expression env x in
                Apply (IdSpecial (Yield, v1), fb [x])
            | None ->
                Apply (IdSpecial (Yield, v1), fb [])
          )
        )
      in
      v2
  )

and anon_choice_paren_exp (env : env) (x : CST.anon_choice_paren_exp) : expr =
  (match x with
  | `Paren_exp x -> parenthesized_expression env x
  | `Choice_member_exp x -> lhs_expression env x
  )

and unary_expression (env : env) (x : CST.unary_expression) : expr =
  (match x with
  | `BANG_exp (v1, v2) ->
      let v1 = token env v1 (* "!" *) in
      let v2 = expression env v2 in
      Apply (IdSpecial (ArithOp G.Not, v1), fb [v2])
  | `TILDE_exp (v1, v2) ->
      let v1 = token env v1 (* "~" *) in
      let v2 = expression env v2 in
      Apply (IdSpecial (ArithOp G.BitNot, v1), fb [v2])
  | `DASH_exp (v1, v2) ->
      let v1 = token env v1 (* "-" *) in
      let v2 = expression env v2 in
      Apply (IdSpecial (ArithOp G.Minus, v1), fb [v2])
  | `PLUS_exp (v1, v2) ->
      let v1 = token env v1 (* "+" *) in
      let v2 = expression env v2 in
      Apply (IdSpecial (ArithOp G.Plus, v1), fb [v2])
  | `Typeof_exp (v1, v2) ->
      let v1 = token env v1 (* "typeof" *) in
      let v2 = expression env v2 in
      Apply (IdSpecial (Typeof, v1), fb [v2])
  | `Void_exp (v1, v2) ->
      let v1 = token env v1 (* "void" *) in
      let v2 = expression env v2 in
      Apply (IdSpecial (Void, v1), fb [v2])
  | `Delete_exp (v1, v2) ->
      let v1 = token env v1 (* "delete" *) in
      let v2 = expression env v2 in
      Apply (IdSpecial (Delete, v1), fb [v2])
  )

and formal_parameters (env : env) ((v1, v2, v3) : CST.formal_parameters) : parameter list =
  let _v1 = token env v1 (* "(" *) in
  let v2 =
    (match v2 with
    | Some (v1, v2, v3) ->
        let v1 = formal_parameter env v1 in
        let v2 =
          List.map (fun (v1, v2) ->
            let _v1 = token env v1 (* "," *) in
            let v2 = formal_parameter env v2 in
            v2
          ) v2
        in
        let _v3 =
          (match v3 with
          | Some tok -> Some (token env tok) (* "," *)
          | None -> None)
        in
        v1::v2
    | None -> [])
  in
  let _v3 = token env v3 (* ")" *) in
  v2

and switch_default (env : env) ((v1, v2, v3) : CST.switch_default) =
  let v1 = token env v1 (* "default" *) in
  let _v2 = token env v2 (* ":" *) in
  let v3 = List.map (statement env) v3 in
  Default (v1, stmt_of_stmts v3)

and switch_body (env : env) ((v1, v2, v3) : CST.switch_body) =
  let _v1 = token env v1 (* "{" *) in
  let v2 =
    List.map (fun x ->
      (match x with
      | `Switch_case x -> switch_case env x
      | `Switch_defa x -> switch_default env x
      )
    ) v2
  in
  let _v3 = token env v3 (* "}" *) in
  v2

and statement (env : env) (x : CST.statement) : stmt =
  (match x with
  | `Export_stmt x -> export_statement env x
  | `Import_stmt (v1, v2, v3) ->
      let v1 = token env v1 (* "import" *) in
      let v2 =
        (match v2 with
        | `Import_clause_from_clause (v1, v2) ->
            let v1 = import_clause env v1 in
            let v2 = from_clause env v2 in
            todo env (v1, v2)
        | `Str x -> string_ env x
        )
      in
      let v3 = semicolon env v3 in
      todo env (v1, v2, v3)
  | `Debu_stmt (v1, v2) ->
      let v1 = identifier env v1 (* "debugger" *) in
      let v2 = semicolon env v2 in
      ExprStmt (idexp v1, v2)
  | `Exp_stmt x -> expression_statement env x
  | `Decl x -> declaration env x
  | `Stmt_blk x -> statement_block env x
  | `If_stmt (v1, v2, v3, v4) ->
      let v1 = token env v1 (* "if" *) in
      let v2 = parenthesized_expression env v2 in
      let v3 = statement env v3 in
      let v4 =
        (match v4 with
        | Some (v1, v2) ->
            let v1 = token env v1 (* "else" *) in
            let v2 = statement env v2 in
            Some v2
        | None -> None)
      in
      If (v1, v2, v3, v4)
  | `Switch_stmt (v1, v2, v3) ->
      let v1 = token env v1 (* "switch" *) in
      let v2 = parenthesized_expression env v2 in
      let v3 = switch_body env v3 in
      Switch (v1, v2, v3)
  | `For_stmt (v1, v2, v3, v4, v5, v6, v7) ->
      let v1 = token env v1 (* "for" *) in
      let v2 = token env v2 (* "(" *) in
      let v3 =
        (match v3 with
        | `Lexi_decl x -> lexical_declaration env x
        | `Var_decl x ->
                let vars = variable_declaration env x in
                todo env vars
        | `Exp_stmt x -> expression_statement env x
        | `Empty_stmt tok -> empty_stmt env tok (* ";" *)
        )
      in
      let v4 =
        (match v4 with
        | `Exp_stmt x -> expression_statement env x
        | `Empty_stmt tok -> empty_stmt env tok (* ";" *)
        )
      in
      let v5 =
        (match v5 with
        | Some x -> expressions env x
        | None -> todo env ())
      in
      let v6 = token env v6 (* ")" *) in
      let v7 = statement env v7 in
      todo env (v1, v2, v3, v4, v5, v6, v7)
  | `For_in_stmt (v1, v2, v3, v4) ->
      let v1 = token env v1 (* "for" *) in
      let v2 =
        (match v2 with
        | Some tok -> token env tok (* "await" *)
        | None -> todo env ())
      in
      let v3 = for_header env v3 in
      let v4 = statement env v4 in
      todo env (v1, v2, v3, v4)
  | `While_stmt (v1, v2, v3) ->
      let v1 = token env v1 (* "while" *) in
      let v2 = parenthesized_expression env v2 in
      let v3 = statement env v3 in
      While (v1, v2, v3)
  | `Do_stmt (v1, v2, v3, v4, v5) ->
      let v1 = token env v1 (* "do" *) in
      let v2 = statement env v2 in
      let _v3 = token env v3 (* "while" *) in
      let v4 = parenthesized_expression env v4 in
      let _v5 = semicolon env v5 in
      Do (v1, v2, v4)
  | `Try_stmt (v1, v2, v3, v4) ->
      let v1 = token env v1 (* "try" *) in
      let v2 = statement_block env v2 in
      let v3 =
        (match v3 with
        | Some x -> Some (catch_clause env x)
        | None -> None)
      in
      let v4 =
        (match v4 with
        | Some x -> Some (finally_clause env x)
        | None -> None)
      in
      Try (v1, v2, v3, v4)
  | `With_stmt (v1, v2, v3) ->
      let v1 = token env v1 (* "with" *) in
      let v2 = parenthesized_expression env v2 in
      let v3 = statement env v3 in
      todo env (v1, v2, v3)
  | `Brk_stmt (v1, v2, v3) ->
      let v1 = token env v1 (* "break" *) in
      let v2 =
        (match v2 with
        | Some tok -> Some (identifier env tok) (* identifier *)
        | None -> None)
      in
      let _v3 = semicolon env v3 in
      Break (v1, v2)
  | `Cont_stmt (v1, v2, v3) ->
      let v1 = token env v1 (* "continue" *) in
      let v2 =
        (match v2 with
        | Some tok -> Some (identifier env tok) (* identifier *)
        | None -> None)
      in
      let _v3 = semicolon env v3 in
      Continue (v1, v2)
  | `Ret_stmt (v1, v2, v3) ->
      let v1 = token env v1 (* "return" *) in
      let v2 =
        (match v2 with
        | Some x -> Some (expressions env x)
        | None -> None)
      in
      let _v3 = semicolon env v3 in
      Return (v1, v2)
  | `Throw_stmt (v1, v2, v3) ->
      let v1 = token env v1 (* "throw" *) in
      let v2 = expressions env v2 in
      let _v3 = semicolon env v3 in
      Throw (v1, v2)
  | `Empty_stmt tok -> empty_stmt env tok (* ";" *)
  | `Labe_stmt (v1, v2, v3) ->
      let v1 = identifier_reference env v1 in
      let _v2 = token env v2 (* ":" *) in
      let v3 = statement env v3 in
      Label (v1, v3)
  )

and method_definition (env : env) ((v1, v2, v3, v4, v5, v6, v7) : CST.method_definition) =
  let v1 = List.map (decorator env) v1 in
  let v2 =
    (match v2 with
    | Some tok -> token env tok (* "static" *)
    | None -> todo env ())
  in
  let v3 =
    (match v3 with
    | Some tok -> token env tok (* "async" *)
    | None -> todo env ())
  in
  let v4 =
    (match v4 with
    | Some x ->
        (match x with
        | `Get tok -> token env tok (* "get" *)
        | `Set tok -> token env tok (* "set" *)
        | `STAR tok -> token env tok (* "*" *)
        )
    | None -> todo env ())
  in
  let v5 = property_name env v5 in
  let v6 = formal_parameters env v6 in
  let v7 = statement_block env v7 in
  todo env (v1, v2, v3, v4, v5, v6, v7)

and array_ (env : env) ((v1, v2, v3) : CST.array_) =
  let v1 = token env v1 (* "[" *) in
  let v2 =
    anon_opt_opt_choice_exp_rep_COMMA_opt_choice_exp env v2
  in
  let v3 = token env v3 (* "]" *) in
  todo env (v1, v2, v3)

and export_statement (env : env) (x : CST.export_statement) =
  (match x with
  | `Export_choice_STAR_from_clause_choice_auto_semi (v1, v2) ->
      let v1 = token env v1 (* "export" *) in
      let v2 =
        (match v2 with
        | `STAR_from_clause_choice_auto_semi (v1, v2, v3) ->
            let v1 = token env v1 (* "*" *) in
            let v2 = from_clause env v2 in
            let v3 = semicolon env v3 in
            todo env (v1, v2, v3)
        | `Export_clause_from_clause_choice_auto_semi (v1, v2, v3) ->
            let v1 = export_clause env v1 in
            let v2 = from_clause env v2 in
            let v3 = semicolon env v3 in
            todo env (v1, v2, v3)
        | `Export_clause_choice_auto_semi (v1, v2) ->
            let v1 = export_clause env v1 in
            let v2 = semicolon env v2 in
            todo env (v1, v2)
        )
      in
      todo env (v1, v2)
  | `Rep_deco_export_choice_decl (v1, v2, v3) ->
      let v1 = List.map (decorator env) v1 in
      let v2 = token env v2 (* "export" *) in
      let v3 =
        (match v3 with
        | `Decl x -> declaration env x
        | `Defa_exp_choice_auto_semi (v1, v2, v3) ->
            let v1 = token env v1 (* "default" *) in
            let v2 = expression env v2 in
            let v3 = semicolon env v3 in
            todo env (v1, v2, v3)
        )
      in
      todo env (v1, v2, v3)
  )

and anon_rep_COMMA_opt_choice_exp (env : env) (xs : CST.anon_rep_COMMA_opt_choice_exp) =
  List.map (fun (v1, v2) ->
    let v1 = token env v1 (* "," *) in
    let v2 =
      (match v2 with
      | Some x -> anon_choice_exp env x
      | None -> todo env ())
    in
    todo env (v1, v2)
  ) xs

and decorator_call_expression (env : env) ((v1, v2) : CST.decorator_call_expression) =
  let v1 = anon_choice_id_ref env v1 in
  let v2 = arguments env v2 in
  todo env (v1, v2)

and update_expression (env : env) (x : CST.update_expression) : expr =
  (match x with
  | `Exp_choice_PLUSPLUS (v1, v2) ->
      let v1 = expression env v1 in
      let (op, t) = anon_choice_PLUSPLUS env v2 in
      Apply (IdSpecial (IncrDecr (op, G.Postfix), t), fb [v1])
  | `Choice_PLUSPLUS_exp (v1, v2) ->
      let (op, t) = anon_choice_PLUSPLUS env v1 in
      let v2 = expression env v2 in
      Apply (IdSpecial (IncrDecr (op, G.Prefix), t), fb [v2])
  )

and public_field_definition (env : env) ((v1, v2, v3) : CST.public_field_definition) =
  let v1 =
    (match v1 with
    | Some tok -> token env tok (* "static" *)
    | None -> todo env ())
  in
  let v2 = property_name env v2 in
  let v3 =
    (match v3 with
    | Some x -> initializer_ env x
    | None -> todo env ())
  in
  todo env (v1, v2, v3)

and lexical_declaration (env : env) ((v1, v2, v3, v4) : CST.lexical_declaration) =
  let v1 =
    (match v1 with
    | `Let tok -> token env tok (* "let" *)
    | `Const tok -> token env tok (* "const" *)
    )
  in
  let v2 = variable_declarator env v2 in
  let v3 =
    List.map (fun (v1, v2) ->
      let v1 = token env v1 (* "," *) in
      let v2 = variable_declarator env v2 in
      todo env (v1, v2)
    ) v3
  in
  let v4 = semicolon env v4 in
  todo env (v1, v2, v3, v4)

and class_heritage (env : env) ((v1, v2) : CST.class_heritage) =
  let _v1 = token env v1 (* "extends" *) in
  let v2 = expression env v2 in
  v2

and property_name (env : env) (x : CST.property_name) : property_name =
  (match x with
  | `Choice_id x ->
        let id = identifier_reference env x in
        PN id
  | `Str x ->
        let s = string_ env x in
        PN s
  | `Num tok ->
        let n = number env tok (* number *) in
        PN n
  | `Comp_prop_name (v1, v2, v3) ->
      let _v1 = token env v1 (* "[" *) in
      let v2 = expression env v2 in
      let _v3 = token env v3 (* "]" *) in
      PN_Computed v2
  )

and jsx_child (env : env) (x : CST.jsx_child) : xml_body =
  (match x with
  | `Jsx_text tok ->
        let s = str env tok (* pattern [^{}<>]+ *) in
        XmlText s
  | `Choice_jsx_elem x ->
        let xml = jsx_element_ env x in
        XmlXml xml
  | `Jsx_exp x ->
        let e = jsx_expression env x in
        XmlExpr e
  )

and switch_case (env : env) ((v1, v2, v3, v4) : CST.switch_case) =
  let v1 = token env v1 (* "case" *) in
  let v2 = expressions env v2 in
  let v3 = token env v3 (* ":" *) in
  let v4 = List.map (statement env) v4 in
  todo env (v1, v2, v3, v4)

and spread_element (env : env) ((v1, v2) : CST.spread_element) =
  let v1 = token env v1 (* "..." *) in
  let v2 = expression env v2 in
  v1, v2

and expressions (env : env) (x : CST.expressions) =
  (match x with
  | `Exp x -> expression env x
  | `Seq_exp x -> sequence_expression env x
  )

and finally_clause (env : env) ((v1, v2) : CST.finally_clause) =
  let v1 = token env v1 (* "finally" *) in
  let v2 = statement_block env v2 in
  todo env (v1, v2)

and jsx_element_ (env : env) (x : CST.jsx_element_) : xml =
  (match x with
  | `Jsx_elem (v1, v2, v3) ->
      let v1 = jsx_opening_element env v1 in
      let v2 = List.map (jsx_child env) v2 in
      let v3 = jsx_closing_element env v3 in
      todo env (v1, v2, v3)
  | `Jsx_self_clos_elem (v1, v2, v3, v4, v5) ->
      let v1 = token env v1 (* "<" *) in
      let v2 = jsx_element_name env v2 in
      let v3 = List.map (jsx_attribute_ env) v3 in
      let v4 = token env v4 (* "/" *) in
      let v5 = token env v5 (* ">" *) in
      todo env (v1, v2, v3, v4, v5)
  )

and anon_choice_id (env : env) (x : CST.anon_choice_id) =
  (match x with
  | `Id tok ->
        let id = identifier env tok (* identifier *) in
        Left id
  | `Choice_obj x ->
        Right (destructuring_pattern env x)
  )

and call_signature (env : env) (v1 : CST.call_signature) : parameter list =
  let xs = formal_parameters env v1 in
  todo env xs

and object_ (env : env) ((v1, v2, v3) : CST.object_) : obj_ =
  let v1 = token env v1 (* "{" *) in
  let v2 =
    (match v2 with
    | Some (v1, v2) ->
        let v1 =
          (match v1 with
          | Some x -> [anon_choice_pair env x]
          | None -> [])
        in
        let v2 =
          List.map (fun (v1, v2) ->
            let _v1 = token env v1 (* "," *) in
            let v2 =
              (match v2 with
              | Some x -> [anon_choice_pair env x]
              | None -> [])
            in
            v2
          ) v2
        in
        v1 @ List.flatten v2
    | None -> [])
  in
  let v3 = token env v3 (* "}" *) in
  v1, v2, v3

and lhs_expression (env : env) (x : CST.lhs_expression) : expr =
  (match x with
  | `Member_exp x -> member_expression env x
  | `Subs_exp x -> subscript_expression env x
  | `Id tok ->
        let id = identifier env tok (* identifier *) in
        todo env id
  | `Choice_get x ->
        let id = reserved_identifier env x in
        todo env id
  | `Choice_obj x -> destructuring_pattern env x
  )

and statement_block (env : env) ((v1, v2, v3, v4) : CST.statement_block) : stmt =
  let v1 = token env v1 (* "{" *) in
  let v2 = List.map (statement env) v2 in
  let v3 = token env v3 (* "}" *) in
  let v4 =
    (match v4 with
    | Some tok -> automatic_semicolon env tok (* automatic_semicolon *)
    | None -> todo env ())
  in
  todo env (v1, v2, v3, v4)

and template_substitution (env : env) ((v1, v2, v3) : CST.template_substitution) =
  let v1 = token env v1 (* "${" *) in
  let v2 = expressions env v2 in
  let v3 = token env v3 (* "}" *) in
  todo env (v1, v2, v3)

and declaration (env : env) (x : CST.declaration) =
  (match x with
  | `Func_decl (v1, v2, v3, v4, v5, v6) ->
      let v1 =
        (match v1 with
        | Some tok -> token env tok (* "async" *)
        | None -> todo env ())
      in
      let v2 = token env v2 (* "function" *) in
      let v3 = identifier env v3 (* identifier *) in
      let v4 = formal_parameters env v4 in
      let v5 = statement_block env v5 in
      let v6 =
        (match v6 with
        | Some tok -> automatic_semicolon env tok (* automatic_semicolon *)
        | None -> todo env ())
      in
      todo env (v1, v2, v3, v4, v5, v6)
  | `Gene_func_decl (v1, v2, v3, v4, v5, v6, v7) ->
      let v1 =
        (match v1 with
        | Some tok -> token env tok (* "async" *)
        | None -> todo env ())
      in
      let v2 = token env v2 (* "function" *) in
      let v3 = token env v3 (* "*" *) in
      let v4 = identifier env v4 (* identifier *) in
      let v5 = formal_parameters env v5 in
      let v6 = statement_block env v6 in
      let v7 =
        (match v7 with
        | Some tok -> automatic_semicolon env tok (* automatic_semicolon *)
        | None -> todo env ())
      in
      todo env (v1, v2, v3, v4, v5, v6, v7)
  | `Class_decl (v1, v2, v3, v4, v5, v6) ->
      let v1 = List.map (decorator env) v1 in
      let v2 = token env v2 (* "class" *) in
      let v3 = identifier env v3 (* identifier *) in
      let v4 =
        (match v4 with
        | Some x -> class_heritage env x
        | None -> todo env ())
      in
      let v5 = class_body env v5 in
      let v6 =
        (match v6 with
        | Some tok -> automatic_semicolon env tok (* automatic_semicolon *)
        | None -> todo env ())
      in
      todo env (v1, v2, v3, v4, v5, v6)
  | `Lexi_decl x -> lexical_declaration env x
  | `Var_decl x ->
        let vars = variable_declaration env x in
        todo env vars
  )

and formal_parameter (env : env) (x : CST.formal_parameter) : parameter =
  (match x with
  | `Id tok ->
        let id = identifier env tok (* identifier *) in
        todo env id
  | `Choice_get x ->
        let id = reserved_identifier env x in
        todo env id
  | `Choice_obj x ->
        let pat = destructuring_pattern env x in
        todo env pat
  | `Assign_pat x ->
        let pat = assignment_pattern env x in
        todo env pat
  | `Rest_param (v1, v2) ->
      let v1 = token env v1 (* "..." *) in
      let v2 = anon_choice_id env v2 in
      todo env (v1, v2)
  )

and jsx_attribute_value (env : env) (x : CST.jsx_attribute_value) =
  (match x with
  | `Str x ->
        let s = string_ env x in
        String s
  | `Jsx_exp x ->
        let e = jsx_expression env x in
        e
  (* ?? an attribute value can be a jsx element? *)
  | `Choice_jsx_elem x ->
        let xml = jsx_element_ env x in
        todo env xml
  | `Jsx_frag x ->
        let xml = jsx_fragment env x in
        todo env xml
  )

let program (env : env) ((v1, v2) : CST.program) : program =
  let v1 =
    (match v1 with
    | Some tok -> token env tok (* pattern #!.* *)
    | None -> todo env ())
  in
  let v2 = List.map (statement env) v2 in
  todo env (v1, v2)


(*****************************************************************************)
(* Entry point *)
(*****************************************************************************)
let parse file =
  let ast =
    Parallel.backtrace_when_exn := false;
    Parallel.invoke Tree_sitter_javascript.Parse.file file ()
  in
  let env = { H.file; conv = H.line_col_to_pos file } in

  try
    program env ast
  with
    (Failure "not implemented") as exn ->
      let s = Printexc.get_backtrace () in
      pr2 "Some constructs are not handled yet";
      pr2 "CST was:";
      CST.dump_tree ast;
      pr2 "Original backtrace:";
      pr2 s;
      raise exn
