import sys
from pathlib import Path

file = Path(sys.argv[1])
file.write_text(
  file.read_text()\
  .replace('    return demo', """
    with demo:
        gr.Markdown(
          'Created by [eformat / stable-diffusion](https://github.com/eformat/stable-diffusion)'
        )
    return demo
""", 1)
)
