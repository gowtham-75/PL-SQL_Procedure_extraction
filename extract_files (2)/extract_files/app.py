from antlr4 import InputStream, CommonTokenStream, FileStream, ParseTreeWalker
from antlr_plsql.PlSqlLexer import PlSqlLexer
from antlr_plsql.PlSqlParser import PlSqlParser
from antlr_plsql.PlSqlParserListener import PlSqlParserListener
import streamlit as st

from pathlib import Path


class ProcedureExtractor(PlSqlParserListener):
    def __init__(self):
        self.procedures = {}
        self.functions={}
    
    def enterCreate_procedure_body(self, ctx: PlSqlParser.Create_procedure_bodyContext):
        procedure_name = ctx.procedure_name().getText()   
        

        self.procedures[procedure_name] = {
            "name": procedure_name,
            "start": ctx.start,
            "stop": ctx.stop,
        }
        
    def enterCreate_function_body(self, ctx: PlSqlParser.Create_function_bodyContext):
        function_name=ctx.function_name().getText()
        
        self.functions[function_name] = {
            "name": function_name,
            "start": ctx.start,
            "stop": ctx.stop,
        }

    

def extract_procedures(file_path: Path) -> dict:

    with file_path.open() as f:
        raw_lines = f.readlines()
    print("lexer..")
    lexer = PlSqlLexer(FileStream(file_path))
    print("Stream starts..")

    stream = CommonTokenStream(lexer)
    stream.fill()
    print("Stream ends..")
    print("Parser starts..")
    parser = PlSqlParser(stream)
    st.write(parser.setTrace(True))
    tree = parser.procedure_body()

    extractor = ProcedureExtractor()
    walker = ParseTreeWalker()
    walker.walk(extractor, tree)

    procedures = extractor.procedures
    functions = extractor.functions

    for procedure_name in procedures:
        start_line = procedures[procedure_name]["start"].line - 1
        stop_line = procedures[procedure_name]["stop"].line + 1
        procedures[procedure_name]["source"] = "".join(raw_lines[start_line:stop_line])
        
    for function_name in functions:
        start_line = functions[function_name]["start"].line - 1
        stop_line = functions[function_name]["stop"].line + 1

        functions[function_name]["source"] = "".join(raw_lines[start_line:stop_line])
    
    return procedures,functions



procedures,functions= extract_procedures(Path("sql_files", "library_fun.sql"))

st.write("Procedures")
for procedure_name,procedure_values in procedures.items():
    st.code(procedures[procedure_name]['source'],language="sql")
    st.divider()

st.write("Functions")
for function_name,function_values in functions.items():
    st.code(functions[function_name]['source'],language='sql')
    st.divider()