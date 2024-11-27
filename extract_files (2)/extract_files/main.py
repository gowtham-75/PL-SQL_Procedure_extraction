import re
from pathlib import Path
import streamlit as st

# A Class to neatly store the extracted procedures, instead of messy dicts
class PLSQL_Procedure:
    def __init__(self, name:str, signature:str, source:str):
        self.name = name
        self.source = source
        self.signature = signature

        self.process_signature()

    def __repr__(self):
        return self.source
    
    def process_signature(self):
        # Extract each part of the signature - parameter name and type
        raw_parameters = self.signature.split(',')

        self.parameters = {}
        for raw_parameter in raw_parameters:
            # Replace more than one space with a single space - using regex
            raw_parameter = re.sub(r"\s+", " ", raw_parameter)

            try:
                if ' IN ' in raw_parameter:
                    param_name, param_type = raw_parameter.strip().split(' IN ')
                elif len(raw_parameter.split()) == 2:
                    param_name, param_type = raw_parameter.strip().split()               
                    
            except ValueError:
                param_name = raw_parameter.strip()
                param_type = ''
                print(f"Unable to split `{raw_parameter.strip()}` into name and type")
            self.parameters[param_name.strip()] = param_type.strip()

# Read the sample sql file
with open(Path("sql_files", "Library_fun.sql"), 'r') as f:
    code = f.read()

# Find all the procedures
procedure_matches = re.findall(r'^(CREATE|CREATE OR REPLACE)\s+(PROCEDURE)(.*?)(^END;) | (PROCEDURE)(.*?)(^END;)', code, flags=re.MULTILINE | re.DOTALL | re.IGNORECASE)

# Regex to extract name and signatures of each procedure
procedure_names_with_signature = re.compile(r'PROCEDURE\s+(\w+)\s*\((.*?)\)', re.IGNORECASE | re.MULTILINE | re.DOTALL)

# Prcoess and store them properly
# st.write(procedure_matches)
# st.write(procedure_names_with_signature)
procedures = []
for pro_match in procedure_matches:
    code_block = " ".join(pro_match)
    procedure_name = procedure_names_with_signature.search(code_block).group(1)
    st.write(procedure_name)
    procedure_signature = procedure_names_with_signature.search(code_block).group(2)
    st.write(procedure_signature)
    procedures.append(PLSQL_Procedure(procedure_name, procedure_signature, code_block))

# # Print Extracted data
# print(procedures[0].name)
# print(procedures[0].signature)
# print(procedures[0].parameters)
# print(procedures[0].source)

st.write(procedures)