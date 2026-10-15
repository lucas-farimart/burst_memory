import secrets

with open("./data/exp1.hex", "w") as arquivo:
    for _ in range(512):
        arquivo.write(f"{secrets.randbits(32):08x}\n")
