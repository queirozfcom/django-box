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
	}->
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


class gui{
	# todo
}

include virtualenvs
include django
include postgrespython
include python
include git


