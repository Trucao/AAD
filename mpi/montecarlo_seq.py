from random import random
from time import perf_counter

TOTAL_PONTOS = 100000000


def monte_carlo(num_pontos: int) -> int:
    pontos_dentro = 0
    for _ in range(num_pontos):
        x = random()
        y = random()
        # Verificando os pontos interiores
        if x**2 + y**2 < 1:
            pontos_dentro += 1

    return pontos_dentro


def main():
    start = perf_counter()

    results = monte_carlo(num_pontos=TOTAL_PONTOS)
    pi = 4 * (results / TOTAL_PONTOS)

    end = perf_counter()

    print(pi)
    print(end - start)


if __name__ == "__main__":
    main()
