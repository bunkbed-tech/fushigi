from .data.load import load_defaults
from .db.generate import seed_pocketbase


def main() -> None:
    seed_pocketbase(load_defaults())
    print("Finished loading default grammar rules into Fushigi db!")


if __name__ == "__main__":
    main()
