from random import random
from time import perf_counter

from mpi4py import MPI

TOTAL_POINTS = 100000000
MASTER_NODE = 0

comm = MPI.COMM_WORLD
n_nodes = comm.Get_size()
rank = comm.Get_rank()


def monte_carlo(num_points: int) -> int:
    pontos_dentro = 0
    for _ in range(num_points):
        x = random()
        y = random()
        # Verificando os pontos interiores
        if x**2 + y**2 < 1:
            pontos_dentro += 1

    return pontos_dentro


def get_num_points() -> int:
    points = TOTAL_POINTS // n_nodes
    remainder = TOTAL_POINTS % n_nodes
    if rank < remainder:
        points += 1

    return points


def main_master():
    start = perf_counter()

    points = get_num_points()
    points_in = monte_carlo(points)
    data = comm.gather(points_in, root=MASTER_NODE)

    pi = 4.0 * sum(data) / TOTAL_POINTS

    end = perf_counter()

    print(pi)
    print(end - start)


def main_worker():
    points = get_num_points()
    points_in = monte_carlo(points)
    comm.gather(points_in, root=MASTER_NODE)


if __name__ == "__main__":
    if rank == MASTER_NODE:
        main_master()
    else:
        main_worker()
