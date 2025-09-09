import json, sys, requests

def main():
    url = sys.argv[1] if len(sys.argv) > 1 else "http://localhost:8000/llm/generate"
    data = {"prompt":"Di hola en español","stream":True,"max_tokens":64}
    # requests envía JSON con UTF-8 sin BOM
    with requests.post(url, json=data, stream=True) as r:
        r.raise_for_status()
        for line in r.iter_lines():
            if line:
                print(line.decode("utf-8"))

if __name__ == "__main__":
    main()
