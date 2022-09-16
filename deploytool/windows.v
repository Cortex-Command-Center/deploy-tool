import os
import term

pub fn deploy_windows(opts BuildOpts) ?
{
	out := windeploy.replace('VERSION', opts.version)

	// Copy data
	copy_data(opts, out) ?

	// Copy libs
	print(term.green('\tCopying libraries... '))
	os.cp_all(winlibs, out, true) ?
	println('DONE!')
	os.flush()

	// Copy exe
	print(term.green('\tCopying 64 bit windows binary... '))
	os.cp(windows, os.join_path(out, winbinname)) ?
	println('DONE!')
	os.flush()

	// If there's a 32bit exe, copy that in too
	if os.exists(oldwindows)
	{
		print(term.green('\tCopying 32 bit windows binary... '))
		os.cp(oldwindows, os.join_path(out, oldwinbinname)) ?
		println('DONE!')
		os.flush()
	}

	// Zip it all up
	run_zip(out, out + '.zip') ?

	// Cleanup
	print(term.green('\tCleaning up... '))
	os.rmdir_all(out) ?
	println('DONE!')
}
