/*
 * Copyright (c) 2019 Hiroshi Hayakawa <hhiroshell@gmail.com>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND
 */

locals {
  instance-image-ocid = {
    // See https://docs.us-phoenix-1.oraclecloud.com/images/
    // Oracle-provided image "Canonical-Ubuntu-18.04-Minimal-2020.08.25-0"
    ap-chuncheon-1   = "ocid1.image.oc1.ap-chuncheon-1.aaaaaaaa4f3s4zgbvtwcyxv4a4ghbe224b25pgm6xht7fbevjhl5at4mpida"
    ap-hyderabad-1   = "ocid1.image.oc1.ap-hyderabad-1.aaaaaaaawjc3lipandj7lxylfbrka7p6zc2nj3gzqqsqou2potgoxk76wkfq"
    ap-melbourne-1   = "ocid1.image.oc1.ap-melbourne-1.aaaaaaaaxh6rqavgy6zlwao64ghuhuchftad4f6s7y5kk4jcou6z62lf2rma"
    ap-mumbai-1      = "ocid1.image.oc1.ap-mumbai-1.aaaaaaaa7lbnymwk2cki7qdywnjvxakliw6xjtrv7od5tti2vwmtk3lzvk2a"
    ap-osaka-1       = "ocid1.image.oc1.ap-osaka-1.aaaaaaaapcnrwzsfmy37alrkcv2j4jkuyl6jrc4jz66pru5xf6eaid2rk7va"
    ap-seoul-1       = "ocid1.image.oc1.ap-seoul-1.aaaaaaaaoa7r3yfuurfnqhfltd453p2yb7pll63lfp5qzw7ijmptrhjbvz3a"
    ap-sydney-1      = "ocid1.image.oc1.ap-sydney-1.aaaaaaaaoleh53spl5cvrvb54syl6nxy4md77pupkrehtc5okfgrfievgrcq"
    ap-tokyo-1       = "ocid1.image.oc1.ap-tokyo-1.aaaaaaaa27lu2aswvgwc7vd7l6gwrnagxlvjzybq5eqedrg6klmaqykoaaba"
    ca-montreal-1    = "ocid1.image.oc1.ca-montreal-1.aaaaaaaa5orh3fe5scqkwnpjd4ak2glhzixiq5v4mqhd4h6lic25labhwppq"
    ca-toronto-1     = "ocid1.image.oc1.ca-toronto-1.aaaaaaaarg7zoxcn63kztvglt3l6kfdxnr4ipmguzauzyaopwj7uutqvskvq"
    eu-amsterdam-1   = "ocid1.image.oc1.eu-amsterdam-1.aaaaaaaabura3z6avfytshsbymfcflgr75ohgotqwrrbne5o5oqmagrn6noa"
    eu-frankfurt-1   = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaajag7koakq7h6nhwofyzalrctekkxa4lsnvtgb56adzfegod5dmpa"
    eu-zurich-1      = "ocid1.image.oc1.eu-zurich-1.aaaaaaaaj4wfdbm5szmfwj52uzdgg4k7zcnllfvv5rf7x4dcyvib5wv2b7vq"
    me-jeddah-1      = "ocid1.image.oc1.me-jeddah-1.aaaaaaaa576wmmzbbtxcb5sotrx4yabie6kaeiyka5pkbjnrvogvvoaxgtsa"
    sa-saopaulo-1    = "ocid1.image.oc1.sa-saopaulo-1.aaaaaaaajvvn6z6o7gbmhaekz4dvadaxhiqs2kjoqstumiqzm4vfmbex4rca"
    uk-london-1      = "ocid1.image.oc1.uk-london-1.aaaaaaaabdbcjkzxbuqordrm7gtsopgkljindcebwalhocziprr7h4xzjplq"
    us-ashburn-1     = "ocid1.image.oc1.iad.aaaaaaaa5cr5r2tsyurtz5hh2sb3cq4qrda4tsll2dwp22snwqwi2qzlvhtq"
    us-gov-ashburn-1 = "ocid1.image.oc3.us-gov-ashburn-1.aaaaaaaanjsc6ey3hwaifs43kyhwu7typzx5qibcc74cbw6afws5wpf4falq"
    us-gov-chicago-1 = "ocid1.image.oc3.us-gov-chicago-1.aaaaaaaajy3embkfmrdedhf3ielyqee5bcbelgw4ogoeuup43v5vgs4vshpa"
    us-gov-phoenix-1 = "ocid1.image.oc3.us-gov-phoenix-1.aaaaaaaahwxzh5fnqv74lpuaw7nx7edwqysxibi7bcfjyflyemg3nhr3b5vq"
    us-langley-1     = "ocid1.image.oc2.us-langley-1.aaaaaaaacclsdxcp6p2qugzjzrvvta335e32khrttf6j73jkgbpfun3igmja"
    us-luke-1        = "ocid1.image.oc2.us-luke-1.aaaaaaaawjrjk66dn6p7ykkebyi6peznqcjk4y6des7tkcpzutyqnbcmvafq"
    us-phoenix-1     = "ocid1.image.oc1.phx.aaaaaaaasit6dalhenmeijklokta5qg2ga62ycuxkugjpwwep6lsvjrycunq"
    us-sanjose-1     = "ocid1.image.oc1.us-sanjose-1.aaaaaaaahh3yy7byc2zndii7zo74x2lbr6tcqbqmcmkwzfnicnapg4wfxibq"
  }
}

resource "tls_private_key" "loadtester-ssh-key-pair" {
  algorithm = "RSA"
}

resource "oci_core_instance" "loadtester" {
  display_name        = "loadtester"
  compartment_id      = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0]["name"]
  shape               = var.core_instance_shape
  create_vnic_details {
    display_name     = "primary-vnic"
    subnet_id        = oci_core_subnet.loadtester-sn-ad1.id
    assign_public_ip = true
  }

  source_details {
    source_type = "image"
    source_id   = local.instance-image-ocid[var.region]
  }

  extended_metadata = {
    ssh_authorized_keys = tls_private_key.loadtester-ssh-key-pair.public_key_openssh
  }

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ubuntu"
    private_key = tls_private_key.loadtester-ssh-key-pair.private_key_pem
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y -f vim git",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
      "sudo add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\"",
      "sudo apt-get update",
      "sudo apt-get install -y docker-ce docker-ce-cli containerd.io",
      "sudo groupadd docker && sudo usermod -aG docker $USER",
      "sudo curl -L \"https://github.com/docker/compose/releases/download/1.27.1/docker-compose-$(uname -s)-$(uname -m)\" -o /usr/local/bin/docker-compose",
      "sudo chmod +x /usr/local/bin/docker-compose",
    ]
  }

  /* 
   * About kernel parameter tuning for gatling,
   * see https://gatling.io/docs/current/general/operations/
   */
  provisioner "remote-exec" {
    inline = [
      "sudo bash -c 'echo \"*       soft    nofile  65535\" >> /etc/security/limits.conf'",
      "sudo bash -c 'echo \"*       hard    nofile  65535\" >> /etc/security/limits.conf'",
      "sudo bash -c 'echo \"session required pam_limits.so\" >> /etc/pam.d/common-session'",
      "sudo bash -c 'echo \"session required pam_limits.so\" >> /etc/pam.d/common-session-noninteractive'",
      "sudo bash -c 'echo \"session required pam_limits.so\" >> /etc/pam.d/sshd'",
      "sudo bash -c 'echo \"UseLogin yes\" >> /etc/ssh/sshd_config'",
      "sudo sysctl -w net.ipv4.ip_local_port_range=\"1025 65535\"",
      "echo 300000 | sudo tee /proc/sys/fs/nr_open",
      "echo 300000 | sudo tee /proc/sys/fs/file-max",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo bash -c 'echo \"net.ipv4.tcp_max_syn_backlog = 40000\" >> /etc/sysctl.conf'",
      "sudo bash -c 'echo \"net.core.somaxconn = 40000\" >> /etc/sysctl.conf'",
      "sudo bash -c 'echo \"net.core.wmem_default = 8388608\" >> /etc/sysctl.conf'",
      "sudo bash -c 'echo \"net.core.rmem_default = 8388608\" >> /etc/sysctl.conf'",
      "sudo bash -c 'echo \"net.ipv4.tcp_sack = 1\" >> /etc/sysctl.conf'",
      "sudo bash -c 'echo \"net.ipv4.tcp_window_scaling = 1\" >> /etc/sysctl.conf'",
      "sudo bash -c 'echo \"net.ipv4.tcp_fin_timeout = 15\" >> /etc/sysctl.conf'",
      "sudo bash -c 'echo \"net.ipv4.tcp_keepalive_intvl = 30\" >> /etc/sysctl.conf'",
      "sudo bash -c 'echo \"net.ipv4.tcp_tw_reuse = 1\" >> /etc/sysctl.conf'",
      "sudo bash -c 'echo \"net.ipv4.tcp_moderate_rcvbuf = 1\" >> /etc/sysctl.conf'",
      "sudo bash -c 'echo \"net.core.rmem_max = 134217728\" >> /etc/sysctl.conf'",
      "sudo bash -c 'echo \"net.core.wmem_max = 134217728\" >> /etc/sysctl.conf'",
      "sudo bash -c 'echo \"net.ipv4.tcp_mem  = 134217728 134217728 134217728\" >> /etc/sysctl.conf'",
      "sudo bash -c 'echo \"net.ipv4.tcp_rmem = 4096 277750 134217728\" >> /etc/sysctl.conf'",
      "sudo bash -c 'echo \"net.ipv4.tcp_wmem = 4096 277750 134217728\" >> /etc/sysctl.conf'",
      "sudo bash -c 'echo \"net.core.netdev_max_backlog = 300000\" >> /etc/sysctl.conf'",
    ]
  }
}

output "loadtester-public-ip" {
  value = [oci_core_instance.loadtester.public_ip]
}

output "loadtester-private-key-pem" {
  value = [tls_private_key.loadtester-ssh-key-pair.private_key_pem]
}
