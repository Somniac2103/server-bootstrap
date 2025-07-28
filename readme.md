Project 1: Bootstrap

Goal: To create a script that can be downloaded then runned locally to create a secure link with an remote ubuntu server then install all the required programs for ansible to work and download a designated repository which will be use in the next phase of setup with ansible.

REQUIREMENTS:
Must get and valdiate all necessary information for the process to run.
Must be able to link to server automatically.
Must install all necessary programs to to enbale anisble to run a playbook on the remote server self.
Must download a repository on the remote server directly which will be used by anisble.

OPTIONAL:
Create new user, password, add to sudoer list and give necessary permission .
Generate a ssh key on local pc and setup ssh connection with remote.
Disable root entirely (no password or login access remotely).
Disable password logon for new user remotely.
Also allow the script to run using arguments in the terminal

EXTRAS:
Generate error for debugging.
Log all activities in console and logfile on local computer.
Run test check to validate all processes has been completed.
Give a completed report with all the secret information in a file on the local pc.