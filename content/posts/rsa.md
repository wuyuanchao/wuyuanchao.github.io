---
title: "RSA"
date: 2025-04-13T13:06:28+08:00
# bookComments: false
# bookSearchExclude: false
---

# RSA encryption

## The fundamental theorem of arithmetic

https://en.wikipedia.org/wiki/Fundamental_theorem_of_arithmetic

任何一个正整数都可以写成有限个素数的积，且这种写法是唯一的。

modular exponentiation
- g, public (primitive root) base, g = 5
- p, public (prime) modulus, p = 23

f(x) = g^x mod p

one way function: easy to perform, hard to reverse

## Diffie–Hellman key exchange

https://en.wikipedia.org/wiki/Diffie%E2%80%93Hellman_key_exchange

mesasge space 
key space
ciphertext space

- g, public (primitive root) base, known to Alice, Bob, and Eve. g = 5
- p, public (prime) modulus, known to Alice, Bob, and Eve. p = 23
- a, Alice's private key, known only to Alice. a = 6
- b, Bob's private key known only to Bob. b = 15
- A, Alice's public key, known to Alice, Bob, and Eve. A = ga mod p = 8
- B, Bob's public key, known to Alice, Bob, and Eve. B = gb mod p = 19

Alice: s = B^a mod 23
Bob: s = A^b mod 23

because: ` (g^a)^b mod p = g^(a*b) mod p = g^(b*a) mod p = (g^b)^a mod p `

幂运算运算律 (a^m)^n=a^(m*n)

Now s is the shared secret key and it is known to both Alice and Bob

## the trapdoor:Euler Totient Exploration

P1 and P2 are prime numbers, N = P1 * P2

P1 * P2 = N is easy to perform, but N is hard to reverse to P1 and P2

Φ(P) = P - 1 

Φ(N) = Φ(P1 * P2) = Φ(P1) * Φ(P2) = (P1 - 1)*(P2 - 1)

where ϕ(n) is Euler's totient function, which counts the number of positive integers ≤ n which are relatively prime to n.

## Euler's theorem

https://brilliant.org/wiki/eulers-theorem/

m^(e*d) mode n = m

prime factorization 

Time Complexity
