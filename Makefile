docker_prune:
	docker system prune -f

apt_update:
	sudo apt update

apt_upgrade:
	sudo apt upgrade -y

apt_clean:
	sudo apt clean -y;
	sudo apt autoremove -y;
