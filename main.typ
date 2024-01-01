#import "style.typ": *

#show: doc => conf(
    title: [
      General math notes
    ],
    doc
)

= Perspective Projection matrix (Reverse depth + D3D/WGPU/Metal coordinate system)

Source: #link(
  "https://vincent-p.github.io/posts/vulkan_perspective_matrix/#classic-perspective-with-a-near-and-far-plane",
  "The perspective projection matrix in Vulkan",
)

== Derivation

#figure(
  image("./imgs/mapping.svg"),
  caption: [
    D3D's coordinate system means bottom left corner is $(-1, -1)$.
  ],
)

#figure(
  image("./imgs/frustum.svg"),
  caption: [
    Full frustum that we need to map to clip space.
  ],
)

#figure(
  image("./imgs/frustum_side.svg"),
  caption: [
    Side view of the frustum projection.
  ],
)

By the intercept theorem we can derive:
$
  x_p/x_e = y_p/y_e = z_p/z_e = (-n)/z_e
$

Hence,
$
  x_p = (1/(-z_e))n x_e\
  y_p = (1/(-z_e))n y_e\
  z_p = -n = (1/(-z_e))n z_e\
$

The GPU does a perspective divide using a 4th dimension denoted by $w_c$, meaning every
component of the clip coordinate is divided by the term $w_c$ automatically.
This helps computing the division using the common factor $-z_e$:

$
  mat(
    dot, dot, dot, dot;
    dot, dot, dot, dot;
    dot, dot, dot, dot;
    0, 0, -1, 0
  ) dot
  mat(x_e ; y_e ; z_e ; 1)
  = mat(x_c; y_c; z_c; w_c)
$

This normalizes the final device coordinates:

$
mat(x_n ; y_n ; z_n ; w_n) = mat(x_c/w_c ; y_c/w_c ; z_c/w_c ; w_c/w_c)
$

#figure(
  image("./imgs/corners.svg"),
  caption: [
    Mapping from the corner coordinates of the frustum to the corresponding corners of the clip volume.

  ],
)

The mapping must be a linear function $f(x) = alpha x + beta$ that converts a point in the near plane
into a device coordinate $(x_p -> x_n, y_p -> y_n, z_p -> z_n)$.
We can derive this mapping using the already known corner coordinates.

For $x$:
$
  f(l) = -1, quad f(r) = 1
$
$
  alpha &= (1 - (-1))/(r - l) = 2/(r - l)\
  f(r) &= 1 = alpha r + beta = (2r)/(r - l) + beta\
  <==> beta &= 1 - (2r)/(r - l) = - (r + l) / (r - l)\
  <==> f(x_p) &= x_n = (2 / (r - l)) x_p - (r + l) / (r - l)
$
For $y$:
$
  f(t) = 1, quad f(b) = -1
$
$
  alpha &= (-1 - 1)/(b - t) = 2/(t - b)\
  f(t) &= 1 = alpha t + beta = (2t)/(t - b) + beta\
  <==> beta &= 1 - (2t)/(t - b) = - (t + b) / (t - b)\
  <==> f(y_p) &= y_n = (2 / (t - b)) y_p - (t + b) / (t - b)
$

Substituting $x_p$ and $y_p$:

$
  x_n &= (2 / (r - l)) x_p - (r + l) / (r - l)\
      &= (2 / (r - l)) 1/(-z_e) n x_e - (r + l) / (r - l)\
      &= (1/(-z_e)) ((2n) / (r - l) x_e + (r + l) / (r - l) z_e)\
      &= (1/(-z_e)) x_c
$
#parbreak()
$
  y_n &= (2 / (t - b)) y_p - (t + b) / (t - b)\
      &= (2 / (t - b)) 1/(-z_e) n y_e - (t + b) / (t - b)\
      &= (1/(-z_e)) ((2n) / (t - b) y_e + (t + b) / (t - b) z_e)\
      &= (1/(-z_e)) y_c
$

This fills the $x$ and $y$ mappings of our matrix:

$
  mat(
    (2n)/(r-l), 0, (r+l)/(r-l), 0;
    0, (2n)/(t-b), (t+b)/(t-b), 0;
    dot, dot, dot, dot;
    0, 0, -1, 0
  ) dot
  mat(x_e ; y_e ; z_e ; 1)
  = mat(x_c; y_c; z_c; w_c)
$

Finally, we can use a system of equations to deduce the mapping for $z_c$. Since
the $z$ coordinate cannot depend from $x$ or $y$, we can fill those terms with zero:

$
  mat(
    (2n)/(r-l), 0, (r+l)/(r-l), 0;
    0, (2n)/(t-b), (t+b)/(t-b), 0;
    0, 0, A, B;
    0, 0, -1, 0
  ) dot
  mat(x_e ; y_e ; z_e ; 1)
  = mat(x_c; y_c; z_c; w_c)
$

By definition,

$
  z_n = z_c / w_c = (A z_e + B) / (-z_e)
$

For a reverse depth rendering, the near plane maps to $1$ and the far plane maps to $0$. We can
use this fact to solve for $A$ and $B$:

$
  z_n = 1 => z_e = -n\
  z_n = 0 => z_e = -f\
$
$
  &cases(
    (A (-n) + B)/(-(-n)) = 1,
    (A (-f) + B)/(-(-f)) = 0,
  )\
  <==> quad &cases(
    B - A n = n,
    B - A f = 0,
  )\
  <==> quad &cases(
    A f - A n = n,
    B = A f
  )\
  <==> quad &cases(
    A  = n / (f - n),
    B = (n f) / (f - n)
  )\
$

Meaning

$
  z_n = 1/(-z_e)(n / (f - n) z_c + (n f) / (f - n))
$

== Asymmetric frustum

$
n = "near plane distance"\
f = "far plane distance"\
mat(
  (2n) / (r - l), 0, (r + l)/(r - l), 0;
  0, (2n)/(t - b), (t + b)/(t - b), 0;
  0, 0, n/(f - n), (n f)/(f - n);
  0, 0, -1, 0
) dot
mat(x_e ; y_e ; z_e ; 1)
= mat(x_c; y_c; z_c; w_c)
$

== Symmetric frustum
$
  l = -r, quad b = -t\
  r - l = 2r, quad r + l = 0\
  t - b = 2t, quad t + b = 0\
  mat(
    (2n) / "width", 0, 0, 0;
    0, (2n)/"height", 0, 0;
    0, 0, n/(f - n), (n f)/(f - n);
    0, 0, -1, 0
  ) dot
  mat(x_e ; y_e ; z_e ; 1)
  = mat(x_c; y_c; z_c; w_c)
$

Alternatively, from the FOV and aspect ratio:

#figure(
  image("./imgs/fov.svg"),
  caption: [
    Vertical field of view
  ],
)

Since $"fov"_y = 2 theta$, then

$
  tan("fov"_y / 2) = "height" / (2n) <==> (2n) / "height" = 1 / tan("fov"_y / 2)\
  (2n) / "width" = (2n) / "width" dot "height" / "height" = (2n) / "height" dot "height" / "width"
  = (2n) / "height" dot ("width" / "height")^(-1)
$

Now define
$
  "focal length" = (2n) / "height" = 1 / tan("fov"_y / 2), quad "aspect ratio" = "width" / "height"
$

And rewrite the matrix as such,

$
  mat(
    "focal length" / "aspect ratio", 0, 0, 0;
    0, "focal length", 0, 0;
    0, 0, n/(f - n), (n f)/(f - n);
    0, 0, -1, 0
  ) dot
  mat(x_e ; y_e ; z_e ; 1)
  = mat(x_c; y_c; z_c; w_c)
$

== Symmetric frustum with infinite far plane

We just need to resolve the limits:
$
  lim_(f -> infinity) n / (f - n) = 0\
  lim_(f -> infinity) (n f) / (f - n) = n * lim_(f -> infinity) f / (f - n) = n * 1 = n
$

Which yields the equation

$
  mat(
    "focal length" / "aspect ratio", 0, 0, 0;
    0, "focal length", 0, 0;
    0, 0, 0, n;
    0, 0, -1, 0
  ) dot
  mat(x_e ; y_e ; z_e ; 1)
  = mat(x_c; y_c; z_c; w_c)
$
