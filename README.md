simple_jobs - A small job runner for one-offs
=====

"simple_jobs" is a small library for kicking up a few thousand small jobs into a
queue for quick one-offs.

The original intention of this library was to be used in the Erlang shell, and
in escripts, but not for use in production or via applications.

This tool uses Erlang Monitors to provide a very basic layer of error aggregation
but any actual reporting you want done you'll need to implement yourself.

Shell Usage
---

Start the shell:

  make shell

Then while in the shell make your job:

  Job = fun() ->
    io:format("I'm a job!", [])
  end.

Then spam it!

  simple_jobs:run(Job, Total).

Escript Usage (via Rebar3)
---

Add this as a dependency of your Rebar3 library for escriptization:

  {deps, [
    {simple_jobs, ".*", {git, "git://github.com/shaneutt/simple_jobs", {branch, "master"}}}
  ]}.
