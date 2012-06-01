#!/usr/bin/env lua

local M = {}

function M.init(opts)
  local lfs     = require("lfs")
  local utils   = require("utils")

  local help = [[usage: vert [--luarocks-version[ [--lua-version] <directory>

  --luarocks-version : luarocks version to install
  --lua-version : lua version to compile
  ]]

  local activate_template = [=[
  # This is a wholesale copy of the activate command generated by `virtualenv`[1]
  # Many thanks to go Ian Bicking and that team for making such a fine piece of
  # software That I find it necessary to build myself similar tools for lua.  This
  # 
  # [1] http://www.virtualenv.org/
  # 
  # file must be used with "source bin/activate" *from your shell* you cannot run
  # it directly

  deactivate () {
      if [[ -n "$_OLD_VERT_PATH" ]]
      then
          PATH=$_OLD_VERT_PATH
          export PATH
          unset _OLD_VERT_PATH
      fi

      if [[ -n "$_OLD_VERT_PS1" ]]
      then
          PS1=$_OLD_VERT_PS1
          export PS1
          unset _OLD_VERT_PS1
      fi

      if [[ -n "$_OLD_LUA_PATH" ]]
          LUA_PATH=$_OLD_VERT_LUA_PATH
          export LUA_PATH
          unset _OLD_VERT_LUA_PATH
      then
          unset LUA_PATH
      fi

      if [[ -n "$_OLD_LUA_CPATH" ]]
          LUA_CPATH=$_OLD_VERT_LUA_CPATH
          export LUA_CPATH
          unset _OLD_VERT_LUA_CPATH
      then
          unset LUA_CPATH
      fi

      unset LUA_VERSION
      unset VERT

      # This should detect bash and zsh, which have a hash command that must
      # be called to get it to forget past commands.  Without forgetting
      # past commands the $PATH changes we made may not be respected
      if [[ -n "$BASH" ]] || [[ -n "$ZSH_VERSION" ]]
      then
          hash -r
      fi

      if [ ! "$1" = "nondestructive" ]
      then
          # Self destruct!
          unset -f deactivate
      fi
  }

  deactivate nondestructive

  LUA_VERSION="%s"
  VERT="%s"

  export LUA_VERSION
  export VERT

  if [[ -z "$VERT_DISABLE_PROMPT" ]]
  then
      _OLD_VERT_PS1="$PS1"
      export _OLD_VERT_PS1

      if [[ "x" != x ]]
      then
          PS1="$PS1"
      else
          PS1="(`basename \"$VERT\"`)$PS1"
      fi

      export PS1
  fi


  if [[ -n "$LUA_PATH" ]]
  then
      _OLD_VERT_LUA_PATH=$LUA_PATH
      export _OLD_VERT_LUA_PATH
  fi

  if [[ -n "$LUA_CPATH" ]]
  then
      _OLD_VERT_LUA_CPATH=$LUA_CPATH
      export _OLD_VERT_LUA_CPATH
  fi

  if [[ -n "$PATH" ]]
  then
      _OLD_VERT_PATH=$PATH
      export _OLD_VERT_PATH
  fi

  LUA_PATH="./?.lua;$VERT/share/lua/$LUA_VERSION/?.lua;$VERT/share/lua/$LUA_VERSION/?/init.lua;$VERT/lib/lua/$LUA_VERSION/?.lua;$VERT/lib/lua/$LUA_VERSION/?/init.lua"
  LUA_CPATH="./?.so; $VERT/lib/lua/$LUA_VERSION/?.so; $VERT/lib/lua/$LUA_VERSION/loadall.so"
  PATH="$VERT/bin:$PATH"

  export LUA_PATH
  export LUA_CPATH
  export PATH

  # This should detect bash and zsh, which have a hash command that must
  # be called to get it to forget past commands.  Without forgetting
  # past commands the $PATH changes we made may not be respected
  if [[ -n "$BASH" ]] || [[ -n "$ZSH_VERSION" ]] ; then
      hash -r
  fi
  ]=]

  local DIRECTORY = utils.expanddir(opts[2])

  if not DIRECTORY then
    print(help)
    return false
  end

  if not utils.isdir(DIRECTORY) then
    lfs.mkdir(DIRECTORY)
  end

  local LUAROCKS_VERSION  = opts["luarocks-version"] or "2.0.8"
  local LUA_VERSION       = opts["lua-version"] or "5.1.5"
  local LUAROCKS_URI      = "http://luarocks.org/releases/"
  local LUA_URI           = "http://www.lua.org/ftp/"
  local LUA_FILENAME      = "lua-"..LUA_VERSION..".tar.gz"
  local LUAROCKS_FILENAME = "luarocks-"..LUAROCKS_VERSION..".tar.gz"
  local BUILD_DIR         = DIRECTORY.."/build/"
  local PLATFORM          = "linux"
  local CURRENT_DIR       = lfs.currentdir()

  if not utils.isdir(BUILD_DIR) then
    lfs.mkdir(BUILD_DIR)
  end

  if not lfs.attributes(BUILD_DIR..LUA_FILENAME) then
    local _, status, _headers = utils.download(LUA_URI..LUA_FILENAME, BUILD_DIR..LUA_FILENAME)
    if status ~= 200 then
      print("Failed to download lua version: "..LUA_VERSION.." at "..LUA_URI..LUA_FILENAME)
      os.exit(2)
    end
  end

  if not lfs.attributes(BUILD_DIR..LUAROCKS_FILENAME) then
    local _, status, _headers = utils.download(LUAROCKS_URI..LUAROCKS_FILENAME, BUILD_DIR..LUAROCKS_FILENAME)
    if status ~= 200 then
      print("Failed to download luarocks version: "..LUAROCKS_VERSION)
      os.exit(2)
    end
  end

  utils.run("tar -xvpf %s -C %s", BUILD_DIR..LUA_FILENAME, BUILD_DIR)
  utils.run("tar -xvpf %s -C %s", BUILD_DIR..LUAROCKS_FILENAME, BUILD_DIR)

  local lua_dir = BUILD_DIR.."lua-"..LUA_VERSION
  local luarocks_dir = BUILD_DIR.."luarocks-"..LUAROCKS_VERSION

  utils.build_lua(lua_dir, "linux", DIRECTORY)
  utils.build_luarocks(luarocks_dir, DIRECTORY)
  utils.write_activate_script(activate_template, LUA_VERSION, DIRECTORY)

  print("ok")
end

return M.init
