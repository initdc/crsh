require "process"

module Crsh
  VERSION = "0.1.0"
end

def builtin_ls(args : Array(String))
  show_dotfiles = false
  if args.includes?("-a") || args.includes?("--all")
    show_dotfiles = true
    args.delete("-a")
    args.delete("--all")
  end

  dir = args.size > 0 ? args[0] : "."

  begin
    entries = Dir.entries(dir).sort
    entries.each do |entry|
      puts entry if show_dotfiles || !entry.starts_with?(".")
    end
  rescue
    puts "ls: cannot access '#{dir}': No such file or directory"
  end
end

def builtin_cd(args : Array(String))
  if args.size != 1
    puts "cd: expected one argument"
    return
  end

  dir = args[0]
  begin
    Dir.cd(dir)
  rescue
    puts "cd: no such file or directory: #{dir}"
  end
end

def builtin_exit(args : Array(String))
  if args.size > 1
    puts "exit: too many arguments"
    return
  end

  exit_code = 0
  if args.size == 1
    begin
      exit_code = Int32.new(args[0])
    rescue
      puts "exit: numeric argument required"
      exit_code = 1
    end
  end

  exit(exit_code)
end

def builtin_help(args : Array(String))
  puts "Available built-in commands:"
  puts "  cd [directory]   Change the current directory to 'directory'."
  puts "  exit [n]        Exit the shell with a status of 'n'."
  puts "  help            Display this help message."
end

def is_builtin_command(command : String) : Bool
  ["ls", "cd", "exit", "help"].includes?(command)
end

def is_crystal_print_command(command : String) : Bool
  ["puts", "p", "pp", "print"].includes?(command)
end

def execute_builtin(command : String, args : Array(String))
  case command
  when "ls"
    builtin_ls(args)
  when "cd"
    builtin_cd(args)
  when "exit"
    builtin_exit(args)
  when "help"
    builtin_help(args)
  end
end

def crystal_eval(code : String)
  args = ["eval", code]
  Process.new("crystal", args: args, input: Process::Redirect::Inherit, output: Process::Redirect::Inherit, error: Process::Redirect::Inherit).wait
end

def evaluate_crystal_print(input : String)
  crystal_eval(input)
end

def run_command(input : String)
  parts = input.strip.split(" ")
  return if parts.empty?

  command = parts[0]
  args = parts[1..-1] || [] of String

  if is_builtin_command(command)
    execute_builtin(command, args)
  elsif is_crystal_print_command(command)
    evaluate_crystal_print(input)
  else
    Process.new(command, args: args, input: Process::Redirect::Inherit, output: Process::Redirect::Inherit, error: Process::Redirect::Inherit).wait
  end
rescue File::NotFoundError
  puts "#{command}: command not found"
end

def main
  loop do
    print "> "
    input = gets
    next if input.nil? || input.strip.empty?
    run_command(input)
  end
end

main
