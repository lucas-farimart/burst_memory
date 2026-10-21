import secrets

with open("./data/randata_8b.hex", "w") as arquivo:
    for _ in range(512):
        arquivo.write(f"{secrets.randbits(8):02x}\n")
