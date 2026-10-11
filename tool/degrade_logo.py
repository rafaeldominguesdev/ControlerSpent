"""Gera o degradê "em malha" da logo (assets/logo/malha_quadrado.png e abertura_fundo.png):

    python3 tool/degrade_logo.py assets/logo/malha_quadrado.png 1024 1024
    python3 tool/degrade_logo.py assets/logo/abertura_fundo.png 603 1311

O degradê passa exatamente pelas 9 cores de referência
(interpolação por funções radiais gaussianas) e é suave em todo o resto."""
import math, struct, sys, zlib

CORES = [  # (x, y) em 0..1 -> cor
    ((0, 0), '#3228D6'), ((0.5, 0), '#3555FE'), ((1, 0), '#3B96FD'),
    ((0, 0.5), '#3457EA'), ((0.5, 0.5), '#366FFD'), ((1, 0.5), '#5ADEEE'),
    ((0, 1), '#3687FE'), ((0.5, 1), '#57D7F3'), ((1, 1), '#73FAE3'),
]
SIGMA = 0.42

def rgb(h): return [int(h[i:i + 2], 16) for i in (1, 3, 5)]

def resolver(A, b):  # eliminação de Gauss
    n = len(A); M = [row[:] + [b[i]] for i, row in enumerate(A)]
    for c in range(n):
        p = max(range(c, n), key=lambda r: abs(M[r][c])); M[c], M[p] = M[p], M[c]
        for r in range(n):
            if r != c:
                f = M[r][c] / M[c][c]
                M[r] = [a - f * bb for a, bb in zip(M[r], M[c])]
    return [M[i][n] / M[i][i] for i in range(n)]

def g(d2): return math.exp(-d2 / (2 * SIGMA * SIGMA))

pts = [p for p, _ in CORES]
A = [[g((a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2) for b in pts] for a in pts]
pesos = [resolver(A, [rgb(c)[k] for _, c in CORES]) for k in range(3)]

def gerar(caminho, w, h):
    xs = [[g((x / (w - 1) - px) ** 2) for x in range(w)] for px in (0, 0.5, 1)]
    linhas = []
    for y in range(h):
        fy = y / (h - 1)
        ey = [g((fy - py) ** 2) for py in (0, 0.5, 1)]
        linha = bytearray([0])
        for x in range(w):
            ex = (xs[0][x], xs[1][x], xs[2][x])
            for k in range(3):
                v = 0.0
                for j in range(3):
                    for i in range(3):
                        v += pesos[k][j * 3 + i] * ex[i] * ey[j]
                linha.append(max(0, min(255, round(v))))
        linhas.append(bytes(linha))
    raw = zlib.compress(b''.join(linhas), 9)
    def chunk(t, d): return struct.pack('>I', len(d)) + t + d + struct.pack('>I', zlib.crc32(t + d) & 0xffffffff)
    png = b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 2, 0, 0, 0)) + chunk(b'IDAT', raw) + chunk(b'IEND', b'')
    open(caminho, 'wb').write(png)

if __name__ == '__main__':
    gerar(sys.argv[1], int(sys.argv[2]), int(sys.argv[3]))
