from flask import Flask, render_template, request
import subprocess
import os

app = Flask(__name__)


def run_khulna_binary(code: str):
    """
    Run the Flex/Bison-based KhulnaScript binary and return:
    - memory_output: the final memory section printed by the C program
    - python_text: the generated Python code section
    - raw_output: full stdout from the binary (for debugging / display)
    - error_output: stderr from the binary, if any
    """
    binary_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "khulna")

    if not os.path.exists(binary_path):
        return "", "", "", "Khulna binary not found. Please run 'make' in the project directory."

    proc = subprocess.run(
        [binary_path],
        input=code.encode("utf-8"),
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )

    stdout = proc.stdout.decode("utf-8", errors="replace")
    stderr = proc.stderr.decode("utf-8", errors="replace")

    memory_output = ""
    python_text = ""

    # Our C parser prints:
    # "Final memory state:\n"
    #   ...
    # "\nGenerated Python code:\n"
    #   ...
    if "Final memory state:" in stdout and "Generated Python code:" in stdout:
        # Be tolerant about the exact newline formatting after the marker
        before_py, py_part = stdout.split("Generated Python code:", 1)
        # strip header line for memory
        mem_lines = before_py.splitlines()
        # Drop the initial prompt line if present and the "Final memory state:" header
        mem_filtered = []
        for line in mem_lines:
            if line.startswith("Enter KhulnaScript code"):
                continue
            if line.strip() == "Final memory state:":
                continue
            if not line.strip():
                continue
            mem_filtered.append(line)
        memory_output = "\n".join(mem_filtered)
        # Drop a leading newline from the Python part if present
        python_text = py_part.lstrip("\n").strip()
    else:
        # Fallback: show whatever stdout we have as raw
        memory_output = stdout.strip()

    return memory_output, python_text, stdout, stderr


@app.route("/", methods=["GET", "POST"])
def index():
    output = ""
    python_text = ""
    code = ""
    error_text = ""

    if request.method == "POST":
        code = request.form.get("code", "")
        output, python_text, raw_out, err = run_khulna_binary(code)
        # If there was an error or we couldn't parse structured sections, show diagnostics
        if err:
            error_text = err

    return render_template(
        "index.html",
        output=output,
        python_text=python_text,
        code=code,
        error_text=error_text,
    )


if __name__ == "__main__":
    # Online-compiler style: bind to all interfaces and disable debug in production
    app.run(host="0.0.0.0", port=5005, debug=True)
