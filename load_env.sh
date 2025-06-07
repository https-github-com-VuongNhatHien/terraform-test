# load_env.sh
#!/bin/bash
export $(grep -v '^#' .env | xargs)
