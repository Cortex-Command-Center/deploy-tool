import os
import term

fn run_zip(src string, out string) ?
{
	print(term.green('\tGenerating zip... '))
	os.flush()
	res := os.execute('zip -r9 "$out" "$src"/*')
	if res.exit_code != 0
	{
		println(term.bright_red('\nFailed to generate zip archive!'))
		println(res.output)
		return error('Failed to generate zip archive!')
	}
	println(' Done!')
	os.flush()
}

fn copy_data(opts BuildOpts, out string) ?
{
	print(term.green('\tCopying data... '))
	os.cp_all(opts.ddir, out, true) ?
	os.rmdir_all(os.join_path(out, '.git')) ?
	os.rmdir_all(os.join_path(out, '.github')) ?
	os.rm(os.join_path(out, '.gitignore')) ?
	println('DONE!')
}