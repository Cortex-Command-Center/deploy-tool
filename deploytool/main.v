import karoscript
import os
import term

import flag


const(
	binaries = 'binaries'
	winlibs = os.join_path(binaries, 'winlibs')
	linlibs = os.join_path(binaries, 'linlibs')
	winbinname = 'Cortex Command x64.exe'
	oldwinbinname = 'Cortex Command x86.exe'
	linbinname = 'CortexCommand'
	windows = os.join_path(binaries, winbinname)
	oldwindows = os.join_path(binaries, oldwinbinname)
	linux = os.join_path(binaries, linbinname)
	lindeploy = 'C4-VERSION-lin64'
	windeploy = 'C4-VERSION-win64'
)


fn main()
{
	// Load options first
	mut opts := BuildOpts{}
	mut parser := karoscript.new_parser_with_userdata(&opts, cb)
	parser.parse_file('deploy_options.ini') ?

	mut dryrun := false

	// Now process the commandline.
	mut fp := flag.new_flag_parser(os.args)
	fp.application('c4-deployment-tool')
	fp.version('0.1.0')
	fp.description('A batteries-included means of managing deployments even for brainlets.')
	fp.skip_executable()


	opts.ddir = fp.string('data', `d`, opts.ddir, 'Path to the cortex command data repo.')
	opts.version = fp.string('version', `v`, opts.version, 'Version tag for the deployed archives.').to_lower()
	opts.linux = fp.bool('linux', `l`, opts.linux, 'Should a linux release be generated?')
	opts.windows = fp.bool('windows', `w`, opts.windows, 'Should a windows release be generated?')
	dryrun = fp.bool('dryrun', `x`, false, 'Does not actually generate archives.')

	additional_args := fp.finalize() ?

	if additional_args.len > 0 {
		println('Unprocessed arguments:\n$additional_args.join_lines()')
	}

	// Validate the final options.
	opts.validate() or
	{
		println(err)
		exit(1)
	}

	// Display the settings for the user.
	println(term.bold('Settings:'))
	println('\t' + term.green('Version: ') + opts.version)
	println('\t' + term.green('Data:    ') + opts.ddir)
	println('\n' + term.bold('Deployments:'))
	println('\t' + term.green('Windows: ') + if opts.windows { 'YES' } else { 'NO' })
	println('\t' + term.green('Linux:   ') + if opts.linux { 'YES' } else { 'NO' })

	println('')
	// Check if we even have a windows bin TO deploy.
	if !os.exists(windows) && opts.windows
	{
		opts.windows = false
		println(term.bright_red('No windows binary available. Windows deploy will not be performed!'))
	}

	// Check if we have a linux bin to deploy.
	if !os.exists(linux) && opts.linux
	{
		opts.linux = false
		println(term.bright_red('No linux binary available. Linux deploy will not be performed!'))
	}

	if !opts.windows && !opts.linux
	{
		println(term.bright_red('No binaries available! Cannot deploy!'))
		exit(2)
	}

	if dryrun
	{
		println(term.yellow('Dry run mode on - quitting early'))
		exit(0)
	}

	mut failed := 0

	if opts.linux
	{
		println(term.bright_magenta('==Building linux archive=='))
		deploy_linux(opts) or
		{
			println(term.bright_red('Linux deploy failed!'))
			println(err)
			failed += 1
		}
		println('')
	}

	if opts.windows
	{
		println(term.bright_magenta('==Building windows archive=='))
		deploy_windows(opts) or
		{
			println(term.bright_red('Windows deploy failed!'))
			println(err)
			failed += 1
		}
		println('')
	}

	if failed > 0
		{ println(term.bright_yellow('Some archives failed to generate!')) }
	else
		{ println(term.bold('Deployment complete!')) }
}


[params]
struct BuildOpts
{
pub mut:
	version string
	windows bool
	linux bool
	edir string
	ddir string
}

fn cb(mut state &BuildOpts, key string, value string) ?
{
	match key
	{
		'version' { state.version = value }
		'datapath' { state.ddir = value }
		'linux' { state.linux = if value.to_lower() in ['1', 'true', 'yes'] { true } else { false } }
		'windows' { state.windows = if value.to_lower() in ['1', 'true', 'yes'] { true } else { false } }
		else {}
	}
}

fn (this BuildOpts) validate() ?
{
	if this.version == '' { return error(term.bold('No version defined!')) }
	if this.ddir == '' { return error(term.bold('No data path defined!')) }

	if !os.is_dir(this.ddir) { return error(term.bold('Data dir [$this.ddir] does not exist!'))}
}
