$username='vagrant'
$project = 'django-blog'
# tell puppet what to prepend to commands
Exec { 
	path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/","/usr/local/bin" ]
} 

# a command to run system updates
exec { 'sys_update':
	command => "apt-get update --fix-missing",
}

class git {
	package{'git-core':
		ensure => 'installed',
		require => Exec['sys_update'],
	}
}

class python {

	package{'python-dev':
		require => Exec['sys_update'],
		ensure => 'installed',
	} ->
	package{'python-pip':
		ensure =>'installed',
		require => Exec['sys_update'],
	} ->
	package{'python-virtualenv':
		ensure => 'installed',
		require => Exec['sys_update'],
	}
}

class virtualenvs{

	file{"project directory with full permissions":
		require => Class['python'],
		path => "/home/${username}/venv",
		owner => "${username}",
		ensure => 'directory',
		mode => '755',
		recurse => true,
	} ->
	exec{"create virtualenv":
		command => "virtualenv venv",
		cwd => "/home/${username}",
		# this will only run if there isn't already a virtualenv for this
		creates => "/home/${username}/venv/bin",
		user => "${username}",
	} ->
	exec {"re-set permissions":
		command => "chmod 755 /home/${username}/ -R"
	} ->
	exec{"activate virtualenv":
	    # activate the virtualenv
	    command =>". /home/${username}/venv/bin/activate",
	    # needed for shell builtins like '.' (source is bash-only)
	    provider => 'shell',
	    user => "${username}",
	}

}

class mysqlpython{
	
	package{'mysql-server':
		ensure => 'installed',
	} ->
	package{'libmysqlclient-dev':
		ensure =>'installed',
	} ->
	exec{'mysql-python':
		require => Class['virtualenvs'],
		# this pip executable should be the virtualenv one
		command =>"/home/${username}/venv/bin/pip install mysql-python",
		user =>"${username}",
	}
}

class postgrespython{
	package{'postgresql-server-dev-9.3':
		ensure => 'installed',
	}
}

class django {
	exec{'Django':
		# this pip executable should be the virtualenv one
		command => "/home/${username}/venv/bin/pip install django-toolbelt",
		user =>"${username}",
		require => Class['postgrespython','virtualenvs','python'],
	} ->
	exec{'South':
		# this pip executable should be the virtualenv one
		command => "/home/${username}/venv/bin/pip install South",
		user =>"${username}",
	} ->
	exec{'dump requirements to file':
		command => "/home/${username}/venv/bin/pip freeze > requirements.txt",
		user => "${username}",
		cwd => "/home/${username}",
	}
}

class sublime{
	file{"/home/${username}/Downloads":
		ensure => 'directory',
		owner => "${username}",
		recurse => true,
	} ->
	exec{'download':
		command => "wget http://c758482.r82.cf2.rackcdn.com/Sublime%20Text%202.0.2.tar.bz2",
		cwd => "/home/${username}/Downloads",
		# only if it hasn't already been done.
		creates => "/home/${username}/Downloads/Sublime Text 2.0.2.tar.bz2",
	} ->
	exec{'extract':
		command => "tar -jxvf Sublime Text 2.0.2.tar.bz2",
		cwd => "/home/${username}/Downloads",
		creates =>"/home/${username}/Downloads/Sublime Text 2",
	} ->
	file{"/home/${username}/Desktop":
		ensure => 'directory',
		owner => "${username}",
		recurse => true,
	} ->
	exec {'create desktop link':
		command => "ln -s /home/${username}/Desktop/sublime_text /home/${username}/Downloads/Sublime Text 2/sublime_text",
		creates => "/home/${username}/Desktop/sublime_text",
	}	
}

class chrome{
	package{'libxss1':
		ensure => 'installed'
	} ->
	file{"/home/${username}/Downloads":
		ensure => 'directory',
		owner => "${username}",
		recurse => true,
	} ->
	exec{'download chrome deb':
		command => 'wget https://dl.google.com/linux/direct/google-chrome-stable_current_i386.deb',
		cwd => "/home/${username}/Downloads",
		creates => "/home/${username}/Downloads/google-chrome-stable_current_i386.deb",
	} ->
	exec{'install chrome':
		command => 'dpkg -i google-chrome-stable_current_i386.deb',
	} -> 
	exec{'add shortcuts to desktop':
		command => "ln -s /usr/bin/google-chrome /home/${username}/Desktop",
	} ->
	exec{'set permissions':
		command => "chmod + /home/${username}/Desktop/*.desktop",
	}
}

class gui{
	
	package{'xubuntu-desktop':
		ensure => 'installed',
		install_options => ' --no-install-recommends',
		# to make sure this gets run last
		require => Class['django'],
	} ->
	package{'xubuntu-icon-theme':
		ensure => 'installed',
	} ->
	exec{'dpkg-reconfigure':
		command => 'dpkg-reconfigure lightdm',
	} ->
	exec{'reboot':
		command => 'reboot',
	}
}


include virtualenvs
include django
include postgrespython
include python
include git
include gui
include sublime
include chrome


