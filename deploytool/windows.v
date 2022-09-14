import os
import term

pub fn deploy_windows(opts BuildOpts) ?
{
	out := windeploy.replace('VERSION', opts.version)

	// Copy data
	copy_data(opts, out) ?

	// Copy libs
	os.cp_all(winlibs, out, true) ?

	// Copy exe
	os.cp(windows, os.join_path(out, winbinname)) ?

	// Zip it all up
	run_zip(out, out + '.zip') ?

	// Cleanup
	print(term.green('\tCleaning up... '))
	os.rmdir_all(out) ?
	println('DONE!')
}
