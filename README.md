# Chip.Fail

Please visit our [website](https://chip.fail/) for details and bare with us while we get our documentation under way.

## Install:

``` sh
virtualenv -p python venv
source venv/bin/activate
pip install -r jupyter/requirements.txt
```

## Run Jupyter:

``` sh
jupyter-lab jupyter/chipfail-glitcher.ipynb
```

## Pinout:
```
GPIO 46 = Trigger In
GPIO 47 = Power Out
GPIO 48 = Glitch Out
```

## Commands:
```
Toggle LED         = b"A" = 65 = 0x41
Power Cycle        = b"B" = 66 = 0x42
Set Pulse Width    = b"C" = 67 = 0x43
Set Delay          = b"D" = 68 = 0x44
Set Power Pulse    = b"E" = 69 = 0x45
Glitch             = b"F" = 70 = 0x46
Read GPIO 0-7      = b"G" = 71 = 0x47
Enable power cycle = b"H" = 72 = 0x48
Get state          = b"I" = 73 = 0x49
```
