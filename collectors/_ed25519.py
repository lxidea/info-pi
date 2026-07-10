"""Minimal pure-Python Ed25519 signing (RFC 8032), stdlib only.

Just enough to sign QWeather JWTs on a Pi that can't install `cryptography`
(compiled wheel + flaky piwheels). Not constant-time — fine for signing our
own short-lived tokens, do NOT use for verifying untrusted input.
"""

import hashlib

b = 256
q = 2 ** 255 - 19
L = 2 ** 252 + 27742317777372353535851937790883648493


def _H(m):
    return hashlib.sha512(m).digest()


def _inv(x):
    return pow(x, q - 2, q)


d = -121665 * _inv(121666) % q
I = pow(2, (q - 1) // 4, q)


def _xrecover(y):
    xx = (y * y - 1) * _inv(d * y * y + 1) % q
    x = pow(xx, (q + 3) // 8, q)
    if (x * x - xx) % q != 0:
        x = (x * I) % q
    if x % 2 != 0:
        x = q - x
    return x


By = 4 * _inv(5) % q
Bx = _xrecover(By)
B = [Bx % q, By % q]


def _edwards(P, Q):
    x1, y1 = P
    x2, y2 = Q
    x3 = (x1 * y2 + x2 * y1) * _inv(1 + d * x1 * x2 * y1 * y2) % q
    y3 = (y1 * y2 + x1 * x2) * _inv(1 - d * x1 * x2 * y1 * y2) % q
    return [x3 % q, y3 % q]


def _scalarmult(P, e):
    # iterative double-and-add (avoids deep recursion)
    Q = [0, 1]
    while e > 0:
        if e & 1:
            Q = _edwards(Q, P)
        P = _edwards(P, P)
        e >>= 1
    return Q


def _encodeint(y):
    return bytes((y >> (8 * i)) & 0xFF for i in range(b // 8))


def _encodepoint(P):
    x, y = P
    val = y | ((x & 1) << (b - 1))
    return bytes((val >> (8 * i)) & 0xFF for i in range(b // 8))


def _bit(h, i):
    return (h[i // 8] >> (i % 8)) & 1


def _clamp(h):
    return 2 ** (b - 2) + sum(2 ** i * _bit(h, i) for i in range(3, b - 2))


def publickey(seed):
    """seed: 32-byte Ed25519 private seed → 32-byte public key."""
    a = _clamp(_H(seed))
    return _encodepoint(_scalarmult(B, a))


def _Hint(m):
    h = _H(m)
    return sum(2 ** i * _bit(h, i) for i in range(2 * b))


def sign(msg, seed, pub=None):
    """Detached Ed25519 signature (64 bytes) of msg with the 32-byte seed."""
    if pub is None:
        pub = publickey(seed)
    h = _H(seed)
    a = _clamp(h)
    r = _Hint(h[b // 8:b // 4] + msg)
    R = _scalarmult(B, r)
    Renc = _encodepoint(R)
    S = (r + _Hint(Renc + pub + msg) * a) % L
    return Renc + _encodeint(S)
