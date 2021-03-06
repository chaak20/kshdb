# -*- shell-script -*-
# stepping.cmd - gdb-like "step" and "skip" debugger commands
#
#   Copyright (C) 2008 Rocky Bernstein rocky@gnu.org
#
#   kshdb is free software; you can redistribute it and/or modify it under
#   the terms of the GNU General Public License as published by the Free
#   Software Foundation; either version 2, or (at your option) any later
#   version.
#
#   kshdb is distributed in the hope that it will be useful, but WITHOUT ANY
#   WARRANTY; without even the implied warranty of MERCHANTABILITY or
#   FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
#   for more details.
#   
#   You should have received a copy of the GNU General Public License along
#   with kshdb; see the file COPYING.  If not, write to the Free Software
#   Foundation, 59 Temple Place, Suite 330, Boston, MA 02111 USA.

# Number of statements to skip before entering the debugger if greater than 0
typeset -i _Dbg_skip_ignore=0

# 1 if we need to ensure we stop on a different line? 
typeset -i _Dbg_step_force=0  

# if positive, the frame level we want to stop at next
typeset -i _Dbg_return_level=-1

# The default behavior of "set different". 
typeset -i _Dbg_set_different=0  

_Dbg_help_add skip \
"skip [COUNT]	-- Skip (don't run) the next COUNT command(s).

If COUNT is given, stepping occurs that many times before
stopping. Otherwise COUNT is one. COUNT an be an arithmetic
expression. See also \"next\" and \"step\"."

# Return 0 if we should skip. Nonzero if there was an error.
# $1 is an optional additional count.
_Dbg_do_skip() {

  _Dbg_not_running && return 1

  typeset count=${1:-1}

  if [[ $count == [0-9]* ]] ; then
    _Dbg_skip_ignore=${count:-1}
    ((_Dbg_skip_ignore--)) # Remove one from the skip caused by this return
  else
    _Dbg_errmsg "Argument ($count) should be a number or nothing."
    _Dbg_skip_ignore=0
    return 3
  fi
  # We're cool. Do the skip.
  _Dbg_write_journal "_Dbg_skip_ignore=$_Dbg_skip_ignore"

  # Set to do a stepping stop after skipping
  _Dbg_step_ignore=0
  _Dbg_write_journal "_Dbg_step_ignore=$_Dbg_step_ignore"
  return 0
}

_Dbg_help_add 'step' \
"step [COUNT] -- Single step a statement COUNT times.

If COUNT is given, stepping occurs that many times before
stopping. Otherwise COUNT is one. COUNT an be an arithmetic
expression.

In contrast to \"next\", functions and source\'d files are stepped
into. 

See also \"next\", \"skip\", \"step-\" \"step+\", and \"set force\"."

_Dbg_help_add 'step+' \
"step+ -- Single step a statement ensuring a different line after the step.

In contrast to \"step\", we ensure that the file and line position is
different from the last one just stopped at.

See also \"step-\" and \"set force\"."

_Dbg_help_add 'step-' \
"step- -- Single step a statement without the \`step force' setting.

Set step force may have been set on. step- ensures we turn that off for
this command. 

See also \"step\" and \"set force\"."

# Step command
# $1 is command step+, step-, or step
# $2 is an optional additional count.
_Dbg_do_step() {

  _Dbg_not_running && return 1

  _Dbg_last_cmd="$1"
  _Dbg_last_next_step_cmd="$1"; shift
  _Dbg_last_next_step_args="$@"

  typeset count=${1:-1}

  case "$_Dbg_last_next_step_cmd" in
      'step+' ) _Dbg_step_force=1 ;;
      'step-' ) _Dbg_step_force=0 ;;
      'step'  ) _Dbg_step_force=$_Dbg_set_different ;;
      * ) ;;
  esac

  if [[ $count == [0-9]* ]] ; then
    _Dbg_step_ignore=${count:-1}
  else
    _Dbg_errmsg "Argument ($count) should be a number or nothing."
    _Dbg_step_ignore=-1
    return 0
  fi

  _Dbg_write_journal_eval "_Dbg_return_level=-1"
  _Dbg_write_journal "_Dbg_step_ignore=$_Dbg_step_ignore"
  _Dbg_write_journal "_Dbg_step_force=$_Dbg_step_force"
  return 1
}

_Dbg_help_add next \
"next [COUNT] -- Single step a statement COUNT times ignoring functions.

If COUNT is given, stepping occurs that many times before
stopping. Otherwise COUNT is one. COUNT an be an arithmetic
expression.

In contrast to \"step\", functions and source\'d files are not stepped
into. 

See also \"step\" \"skip\", \"next-\" \"next+\", and \"set force\"."

_Dbg_help_add 'next+' \
"next+ -- Next stepping ensuring a different line after the step.

In contrast to \"next\", we ensure that the file and line position is
different from the last one just stopped at.

See also \"next-\", \"next\" and \"set force\"."

_Dbg_help_add 'next-' \
"next- -- Next stepping a statement without the \`set force' setting.

Set step force may have been set on. step- ensures we turn that off for
this command. 

See also \"next+\", \"next\" and \"set force\"."

# Next command
# $1 is command next+, next-, or next
# $2 is an optional additional count.
_Dbg_do_next() {

  _Dbg_not_running && return 1

  _Dbg_last_cmd="$1"
  _Dbg_last_next_step_cmd="$1"; shift
  _Dbg_last_next_step_args="$@"

  typeset count=${1:-1}

  case "$_Dbg_last_next_step_cmd" in
      'next+' ) _Dbg_step_force=1 ;;
      'next-' ) _Dbg_step_force=0 ;;
      'next'  ) _Dbg_step_force=$_Dbg_set_different ;;
      * ) ;;
  esac

  if [[ $count == [0-9]* ]] ; then
    _Dbg_step_ignore=${count:-1}
  else
    _Dbg_errmsg "Argument ($count) should be a number or nothing."
    _Dbg_step_ignore=1
    return 0
  fi

  _Dbg_write_journal_eval "_Dbg_return_level=${#_Dbg_frame_stack[@]}"
  _Dbg_write_journal "_Dbg_step_ignore=$_Dbg_step_ignore"
  _Dbg_write_journal "_Dbg_step_force=$_Dbg_step_force"
  return 1
}

_Dbg_alias_add 'n' next
_Dbg_alias_add 'n+' 'next+'
_Dbg_alias_add 'n-' 'next-'
_Dbg_alias_add 's' step
_Dbg_alias_add 's+' 'step+'
_Dbg_alias_add 's-' 'step-'
