# -*- shell-script -*-
# source command.
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

# Handle command-file source. If the filename's okay we just increase the
# input-file descriptor by one and redirect input which will
# be picked up in next debugger command loop.

_Dbg_help_add source \
'source FILE -- Run debugger commands in FILE.'

_Dbg_do_source() {
  typeset filename
  if (( $# == 0 )) ; then
    _Dbg_errmsg 'Need to give a filename for the "source" command.'
    return 1
  fi
  _Dbg_glob_filename "$1"
  if [[ -r $filename ]] || [[ "$filename" == '/dev/stdin' ]] ; then
      # Open new input file descriptor and save number in _Dbg_fd.
      exec {_Dbg_fd[++_Dbg_fd_last]}<"$filename"
      # We'll store the filename for good measure too.
      _Dbg_cmdfile+=("$filename")
  else
    _Dbg_errmsg "Source file $filename is not readable."
  fi
  return 0
}
