#import "theorems.typ": *

#let definition = thmbox("definition", "Definition", inset: (x: 1.2em, top: 1em)).with(numbering: none)

#let theorem = thmbox(
  "theorem",
  "Theorem",
  fill: rgb("#e8e8f8")
).with(numbering: none)

#let lemma = thmplain(
  "lemma",
  "Lemma",
  base: "theorem",
  titlefmt: strong
).with(numbering: none)

#let proof = thmplain(
  "proof",
  "Proof",
  base: "theorem",
  bodyfmt: body => [#body #h(1fr) $square$]
).with(numbering: none)

#let conf(
  title: none,
  doc
) = {
  set page(
    paper: "us-letter"
  )

  set align(center)
  text(17pt, title)

  set align(left)
  set enum(numbering: "a.1)")
  set math.mat(gap: 0.5em)
  show enum: a => block(a, width: 100%)
  show link: underline
  doc
}
