# -*- shell-script -*-
# fns.sh - Debugger Utility Functions
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

# Return $2 copies of $1. If successful, $? is 0 and the return value
# is in result.  Otherwise $? is 1 and result ''
function _Dbg_copies { 
    result=''
    (( $# < 2 )) && return 1
    typeset -r string=$1
    typeset -i count=$2 || return 2;
    (( count > 0 )) || return 3
    result=$(printf "%${count}s" ' ') || return 3
    result=${result// /$string}
    return 0
}

# _Dbg_defined returns 0 if $1 is a defined variable or 1 otherwise. 
function _Dbg_defined {
  (set | grep "^$1=")2>&1 >/dev/null 
  if [[ $? != 0 ]] ; then 
    return 1
  else
    return 0
  fi
}

# Add escapes to a string $1 so that when it is read back via "$1"
# it is the same as $1.
function _Dbg_esc_dq {
  echo $1 | sed -e 's/[`$\"]/\\\0/g' 
}

# Add escapes to a string $1 so that when it is read back via "$1"
# it is the same as $1.
function _Dbg_onoff {
  typeset onoff='off.'
  (( $1 != 0 )) && onoff='on.'
  echo $onoff
}

# Set $? to $1 if supplied or the saved entry value of $?. 
function _Dbg_set_dol_q {
  [[ $# -eq 0 ]] && return $_Dbg_debugged_exit_code
  return $1
}

# Split $2 using $1 as the split character.  We accomplish this by
# temporarily resetting the variable IFS (input field separator).
#
# Example:
# typeset -a a=($(_Dbg_split ":" "file:line"))
# a[0] will have file and a{1] will have line.

function _Dbg_split {
  typeset old_IFS=$IFS
  typeset new_ifs=${1:-' '}
  shift
  typeset -r text=$*
  typeset -a array
  IFS="$new_ifs"
  array=( $text )
  echo ${array[@]}
  IFS=$old_IFS
}

# _Dbg_is_function returns 0 if $1 is a defined function or nonzero otherwise. 
# if $2 is nonzero, system functions, i.e. those whose name starts with
# an underscore (_), are included in the search.
function _Dbg_is_function {
    typeset needed_fn=$1
    [[ -z $needed_fn ]] && return 1
    typeset -i include_system=${2:-0}
    [[ ${needed_fn:0:1} == '_' ]] && ((include_system)) && {
	return 0
    }
    typeset -pf $needed_fn 2>&1 >/dev/null
    return $?
}

# _get_function echoes a list of all of the functions.
# if $1 is nonzero, system functions, i.e. those whose name starts with
# an underscore (_), are included in the search.
# FIXME add parameter search pattern.
function _Dbg_get_functions {
    typeset -i include_system=${1:-0}
    typeset    pat=${2:-*}
    typeset  line
    typeset -a ret_fns=()
    typeset -i invert=0;
    if [[ $pat == !* ]] ; then 
	# Remove leading !
	pat=#{$pat#!}
	invert=1
    fi	
    echo 'Not done yet'
    return 0
    typeset -p +f | while read line ; do
	fn=${line% #*}
	[[ $fn == _* ]] && (( ! $include_system )) && continue
	if [[ $fn == $pat ]] ; then 
	     [[ $invert == 0 ]] && ret_fns[${#ret_fns[@]}]=$fn
	else
	     [[ $invert != 0 ]] && ret_fns[${#ret_fns[@]}]=$fn
	fi
    done
    echo ${ret_fns[@]}
}

# Common routine for setup of commands that take a single
# linespec argument. We assume the following variables 
# which we store into:
#  filename, line_number, full_filename

function _Dbg_linespec_setup {
  typeset linespec=${1:-''}
  if [[ -z $linespec ]] ; then
    _Dbg_msg "Invalid line specification, null given"
  fi
  typeset -a word=($(_Dbg_parse_linespec "$linespec"))
  if [[ ${#word[@]} == 0 ]] ; then
    _Dbg_msg "Invalid line specification: $linespec"
    return
  fi
  
  filename=${word[2]}
  typeset -ir is_function=${word[1]}
  line_number=${word[0]}
  full_filename=`_Dbg_is_file $filename`

  if (( is_function )) ; then
      if [[ -z $full_filename ]] ; then 
	  _Dbg_readin "$filename"
	  full_filename=`_Dbg_is_file $filename`
      fi
  fi
}

# Parse linespec in $1 which should be one of
#   int
#   file:line
#   function-num
# Return triple (line,  is-function?, filename,)
# We return the filename last since that can have embedded blanks.
function _Dbg_parse_linespec {
  typeset linespec=$1
  eval "$_seteglob"
  case "$linespec" in

    # line number only - use .sh.file for filename
    $int_pat )	
      echo "$linespec 0 ${.sh.file}"
      ;;
    
    # file:line
    [^:][^:]*[:]$int_pat )
      # Split the POSIX way
      typeset line_word=${linespec##*:}
      typeset file_word=${linespec%${line_word}}
      file_word=${file_word%?}
      echo "$line_word 0 $file_word"
      ;;

    # Function name or error
    * )
      if _Dbg_is_function $linespec ${_Dbg_debug_debugger} ; then 
	set -x
	typeset -a word==( $(typeset -p +f $linespec) )
	typeset -r fn=${word[1]%\(\)}
	echo "${word[3]} 1 ${word[4]}"
	set +x
      else
	echo ''
      fi
      ;;
   esac
}

# Does things to after on entry of after an eval to set some debugger
# internal settings  
function _Dbg_set_debugger_internal {
  IFS="$_Dbg_space_IFS";
  PS4='+ dbg (${.sh.file}:${LINENO}[${.sh.subshell}]): ${.sh.fun}
'
  PS4='${.sh.file}:${LINENO}:[${.sh.subshell}]): ${.sh.fun}
'
}

function _Dbg_restore_user_vars {
  IFS="$_Dbg_space_IFS";
  set -$_Dbg_old_set_opts
  IFS="$_Dbg_old_IFS";
  PS4="$_Dbg_old_PS4"
}

# Do things for debugger entry. Set some global debugger variables
# Remove trapping ourselves. 
# We assume that we are nested two calls deep from the point of debug
# or signal fault. If this isn't the constant 2, then consider adding
# a parameter to this routine.

function _Dbg_set_debugger_entry {

  typeset -i adjust_level=${1:-0}
  ((.sh.level -= $adjust_level))
  _cur_fn="${.sh.file}"
  let _curline=${.sh.lineno}
  ((_curline < 1)) && let _curline=1

  _Dbg_old_IFS="$IFS"
  _Dbg_old_PS4="$PS4"
  _Dbg_stack_pos=$_Dbg_STACK_TOP
  _Dbg_listline=_curline
  _Dbg_set_debugger_internal
}

function _Dbg_set_to_return_from_debugger {
  _Dbg_rc=$?

  _Dbg_currentbp=0
  _Dbg_stop_reason=''
  if (( $1 != 0 )) ; then
    _Dbg_last_ksh_command="$_Dbg_ksh_command"
    _Dbg_last_curline="$_curline"
    _Dbg_last_source_file="${.sh.file}"
  else
    _Dbg_last_curline==${KSH_LINENO[1]}
    _Dbg_last_source_file=${KSH_SOURCE[2]:-$_Dbg_bogus_file}
    _Dbg_last_ksh_command="**unsaved _kshdb command**"
  fi

  _Dbg_restore_user_vars
}

# Add escapes to a string $1 so that when it is read back via "$1"
# it is the same as $1.
function _Dbg_onoff {
  typeset onoff='off.'
  (( $1 != 0 )) && onoff='on.'
  echo $onoff
}