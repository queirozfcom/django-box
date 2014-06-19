$username='vagrant'

# tell puppet what to prepend to commands
Exec { 
	path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/","/usr/local/bin" ]
} 

# a command to run system updates
exec { 'sys_update':
	command => "apt-get update --fix-missing"
}



class git {
	package{'git-core':
		ensure => 'installed',
		require => Exec['sys_update'],
	}
}

class python {
	package{'python-pip':
		ensure =>'installed',
		notify => Exec['sys_update'],
	}->
	package{'virtualenv':
		ensure => 'installed', 
		provider => 'pip',
	}
}

class virtualenvs{
	include python

	file{"project directory":
		path => "/home/${username}/test-project",
		ensure => 'directory',
	}->
	exec{"virtualenv test-project":
		# this will only run if there isn't already a virtualenv for this
		cwd => "/home/${username}",
		creates => "/home/${username}/test-project/bin",
	}

	# activate the virtualenv
	exec{"source activate":
	    command =>". /home/${username}/test-project/bin/activate",
	    # needed for shel builtins like '.' (source is bash-only)
	    provider => 'shell',
		require => File['project directory'],
	}

}

class django {
	include python
	include virtualenvs
	include mysql_python

	package{'Django':
		ensure=>'installed',
		provider =>'pip',
	}

}

class mysql_python{
	include virtualenvs

	package{'python-dev':
		ensure => 'installed',
	}->
	package{'mysql-server':
		ensure => 'installed',
	}->
	package{'libmysqlclient-dev':
		ensure =>'installed',
	}->
	package{'MySQL-python':
		ensure => 'installed',
		provider => 'pip',
	}	

}

class gui{
	# todo
}


include python
include git
include django


