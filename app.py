from flask import Flask, render_template, request
import re

app = Flask(__name__)

def run_khulna_script(code):
    memory = {"x": 4, "y": 2, "i": 1}

    def execute(line):
        line = line.replace(";", "").strip()

        if "barai dao" in line:
            var = line.split()[0]
            memory[var] += 1
            return f"{var} += 1"

        elif "jog dao" in line:
            var, _, left, _, _, num = line.split()
            memory[var] = memory[left] + int(num)
            return f"{var} = {left} + {num}"

        elif "gun dao" in line:
            var, _, left, _, _, right = line.split()
            memory[var] = memory[left] * memory[right]
            return f"{var} = {left} * {right}"

        elif "rakho" in line:
            var, _, val = line.split()
            memory[var] = memory[val]
            return f"{var} = {val}"

        return ""

    lines = code.strip().split("\n")

    if_block = []
    else_block = []
    in_if = False
    in_else = False
    condition = ""

    for line in lines:
        line = line.strip()

        if line.startswith("jodi"):
            condition = re.search(r"\((.*?)\)", line).group(1)
            in_if = True
            in_else = False

        elif line.startswith("na hoile"):
            in_if = False
            in_else = True

        elif line == "}":
            in_if = False
            in_else = False

        else:
            if in_if:
                if_block.append(line)
            elif in_else:
                else_block.append(line)

    # -------- Generate Python Code --------
    python_lines = []
    python_lines.append(f"if {condition.replace('somman', '==')}:")

    for stmt in if_block:
        py = execute(stmt)
        if py:
            python_lines.append("    " + py)

    if else_block:
        python_lines.append("else:")
        for stmt in else_block:
            py = execute(stmt)
            if py:
                python_lines.append("    " + py)

    return memory, "\n".join(python_lines)


@app.route("/", methods=["GET", "POST"])
def index():
    output = ""
    python_text = ""
    code = ""

    if request.method == "POST":
        code = request.form["code"]
        result, python_text = run_khulna_script(code)
        output = "\n".join([f"{k} = {v}" for k, v in result.items()])

    return render_template("index.html", output=output,
                           python_text=python_text, code=code)

if __name__ == "__main__":
    app.run(debug=True)
