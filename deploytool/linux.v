import os
import term

fn generate_appimage_yaml(opts BuildOpts) ?
{
	print(term.green('\tGenerating AppImageBuilder.yml... '))
	os.flush()
	mut data := os.read_file('stub.AppImageBuilder.yml') ?
	data = data.replace('%VERSION', opts.version)

	os.write_file('AppImageBuilder.yml', data) ?
	println('DONE!')
	os.flush()
}

fn build_app_image(opts BuildOpts) ?
{
	os.chdir('appimage') ?
	generate_appimage_yaml(opts) ?

	bindir := os.join_path('AppDir', 'usr', 'bin')
  	icon_dir := os.join_path('AppDir', 'usr', 'share', 'icons') 
	lib_dir := os.join_path('AppDir', 'usr', 'lib') 
  	outname := os.join_path(bindir, linbinname)

	print(term.green('\tInstalling linux executable for appimage generation... '))
	os.mkdir_all(bindir, os.MkdirParams{}) ?
	os.mkdir_all(icon_dir, os.MkdirParams{}) ?
	os.mkdir_all(lib_dir, os.MkdirParams{}) ?
	os.cp(os.join_path('..', linux), outname) ?
	os.cp(os.join_path('..', 'binaries', 'linlibs', 'libfmod.so.12'), os.join_path(lib_dir, 'libfmod.so.12')) ?
  	os.cp('cccc.png', os.join_path(icon_dir, 'cccc.png')) ?
  //	os.cp('cortexcommand.desktop', os.join_path('AppDir', 'cortexcommand.desktop')) ?
	println('DONE!')

	
	print(term.green('\tBuilding appimage... '))
	os.flush()
	res := os.execute('appimage-builder --skip-test')
	if res.exit_code != 0
		{ return error('appimage-builder failed: $res.output') }
	println('DONE!')
//	println(res.output)
	os.flush()

	print(term.green('\tCleaning up... '))
	os.rmdir_all('AppDir') ?
	//os.rmdir_all('appimage-builder-cache') ?
	os.rm('AppImageBuilder.yml') ?
	println('DONE!')
	os.chdir('..') ?
	
}

pub fn deploy_linux(opts BuildOpts) ?
{
	// We have to generate an appimage first.
	build_app_image(opts) ?

	out := lindeploy.replace('VERSION', opts.version)

	// Copy data
	copy_data(opts, out) ?

	// Copy libs (fmod basically)
	os.cp_all(linlibs, out, true) ?

	aimage := 'C4-$opts.version-x86_64.AppImage'
	// Make appimage executable
	os.chmod(os.join_path('appimage', aimage), 0o740) ?
	// Copy appimage
	os.cp(os.join_path('appimage', aimage), os.join_path(out, aimage)) ?

	// Zip it up
	run_zip(out, out + '.zip') ?

	// Clean up intermediate files
	print(term.green('\tCleaning up... '))
	os.rmdir_all(out) ?
	os.rm(os.join_path(
		'appimage',
		'C4-$opts.version-x86_64.AppImage'
	)) ?
	println('DONE!')
}
