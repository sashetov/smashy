#!/bin/bash
python3 -m venv venv
source venv/bin/activate
sudo ./venv/bin/pip3 install --no-cache-dir -r requirements.txt
deactivate