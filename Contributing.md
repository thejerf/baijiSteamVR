# Contributing to Baiji

In an era of AI, the value you bring to a PR
submitted to any project *IS NOT THE CODE*. Code may not be free yet,
but its value is rapidly dropping.

Or, in other words, I have an AI too. The utility to me of just
shoving some AI code at the project is fairly limited.

The value you bring is [in the
*TESTING*](https://jerf.org/iri/post/2026/what_value_code_in_ai_era/).

You may develop code in any way you like for Baiji, but the value is
in the testing, not a code dump.

Once you have a tested branch in your local repo(s), the AI can walk
you through the process of creating a PR if you don't already
know. The PR prompt will hopefull guide you in this as well, but
please tell us all what testing you have done on your PR.

That doesn't mean you need to have tested every possible interaction
with every possible feature on every possible game. Goodness knows
Baiji's work doesn't even remotely rise to that standard either! But
it is very helpful to know what testing has and has not been done, so
we can know what to look out for, and others may know to make their
own PRs against your PR. Do not be shy to say "I haven't tested this
with X". The space of "all possible Wii and Gamecube games" is
huge.

Because the true value of a PR is testing, note that _testing_ someone
else's PR can be as valuable or even more valuable than coming up with
one of your own. Before starting a PR check the PR tab and see if
there's anything either close to your work or is what you'd have
made. If so, please join with that PR rather than source a new
one by building that PR yourself and running it on your local Steam
Frame. There is nothing as valuable as the _second_ pair of eyes on a
PR!

# Baiji's Scope

The scope of Baiji is:

* The UI as it is presented in Steam OS.
* The stereoscopic and VR views.

The Baiji project will not fix game-specific emulation bugs, unless
someone can make an extremely good case for why it really is a Steam
Frame-specific issue. Fixing emulation bugs is a frought process of
testing hundreds of games for regressions, having deep knowledge of
the relevant systems, and testing, testing, testing. Resources Baiji
does not have.

At most, if someone wants to port in the latest Dolphin work, and then
test it and see that it is some sort of improvement, I might take
that. But it's the only emulation improvement we're going to take.

As such, all Issues filed about games will be closed without
work. Replicate them in the latest official Dolphin release and file
them there, if they are still a problem.

Plus this keeps us out of hot water with Nintendo. We haven't touched
the parts of Dolphin Nintendo cares about.
