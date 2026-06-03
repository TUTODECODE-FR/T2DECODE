#!/usr/bin/env python3
import sys
import atheris

def TestOneInput(data):
    if len(data) > 0 and data[0] == 0x41:
        pass

def main():
    atheris.instrument_all()
    atheris.Setup(sys.argv, TestOneInput)
    atheris.Fuzz()

if __name__ == "__main__":
    main()
