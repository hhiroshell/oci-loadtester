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
        // Oracle-provided image "Oracle-Linux-6.10-2019.08.02-0"
        ap-mumbai-1    = "ocid1.image.oc1.ap-mumbai-1.aaaaaaaae7wf2oyhqq45oius5y7lzbs4vgbioaue24rzzayjfdmhv3jkx2xq"
        ap-seoul-1     = "ocid1.image.oc1.ap-seoul-1.aaaaaaaapwlyu3dtjeskcchf7f5cbm54ghi426htb6lvkgzrbehgkzwgq7aq"
        ap-tokyo-1     = "ocid1.image.oc1.ap-tokyo-1.aaaaaaaarwx3indflmgjwdgeoxge3vsasdbkdowsrxb5p6g7k635vwmqun3a"
        ca-toronto-1   = "ocid1.image.oc1.ca-toronto-1.aaaaaaaaz6jvtjknnxhkzk3cja2uear5vgmwmubeur2dhj6ofijbatyipvaq"
        eu-frankfurt-1 = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaas5n4xc7zfrzg42pq7yvlkhimmsug4p27uylpgi2l5ja2o3hhcyuq"
        eu-zurich-1    = "ocid1.image.oc1.eu-zurich-1.aaaaaaaarztkkowway3ec7lk5h2riuis6a3d2f6qwgrdneeczbawuog47fna"
        uk-london-1    = "ocid1.image.oc1.uk-london-1.aaaaaaaauyqawuj67nro2s3ej6dce2qrthfx5iats3m7pclqcvh3d2y35nma"
        us-ashburn-1   = "ocid1.image.oc1.iad.aaaaaaaaqaedrqy4ugykvsp25nfx5ozotnmgs4fdgc65rmq4aru7mss4ga3a"
        us-langley-1   = "ocid1.image.oc2.us-langley-1.aaaaaaaaqhnu5vu5wod452kwk7invmhf3xwcylkutyqana6msps6fnoxrdjq"
        us-luke-1      = "ocid1.image.oc2.us-luke-1.aaaaaaaa2axsqcwjwpb377i4uoif3gw4rbbmrmjdsgoditazcvuy6t3vxp4a"
        us-phoenix-1   = "ocid1.image.oc1.phx.aaaaaaaaoxrc5doxp7zoi7w6z6td6sqxjwzs2criwblz2arstmtjuy53smta"
    }

    gatling-version = "3.2.0"
    gatling-archive = "gatling-charts-highcharts-bundle-${local.gatling-version}-bundle.zip"
    gatling-base = "/home/opc/gatling"
    gatling-home = "${local.gatling-base}/gatling-charts-highcharts-bundle-${local.gatling-version}"

}

resource "tls_private_key" "loadtester-ssh-key-pair" {
    algorithm   = "RSA"
}

resource "oci_core_instance" "loadtester" {
    display_name        = "loadtester"
    compartment_id      = "${var.compartment_ocid}"
    availability_domain = "${lookup(data.oci_identity_availability_domains.ads.availability_domains[0], "name")}"
    shape               = "${var.core_instance_shape}"
    create_vnic_details {
        display_name     = "primary-vnic"
        subnet_id        = "${oci_core_subnet.loadtester-sn-ad1.id}"
        assign_public_ip = true
    }

    source_details {
        source_type = "image"
        source_id   = "${local.instance-image-ocid["${var.region}"]}"
    }

    extended_metadata = {
        ssh_authorized_keys = "${tls_private_key.loadtester-ssh-key-pair.public_key_openssh}"
    }

    connection {
        type        = "ssh"
        host        = "${self.public_ip}"
        user        = "opc"
        private_key = "${tls_private_key.loadtester-ssh-key-pair.private_key_pem}"
    }

    provisioner "remote-exec" "install jdk & gatling" {
        inline = [
            "sudo yum -y update",
            "sudo yum -y install java-1.8.0-openjdk",
            "wget https://repo1.maven.org/maven2/io/gatling/highcharts/gatling-charts-highcharts-bundle/${local.gatling-version}/${local.gatling-archive} -O /tmp/${local.gatling-archive}",
            "mkdir ~/gatling",
            "unzip /tmp/${local.gatling-archive} -d ${local.gatling-base}",
        ]
    }

    provisioner "remote-exec" "preparation for copying files" {
        inline = [
            "mkdir ${local.gatling-home}/user-files/simulations/atpstore",
        ]
    }

    provisioner "file" {
        source = "./gatling-home/simulations/atpstore/atpstoreRead.scala"
        destination = "${local.gatling-home}/user-files/simulations/atpstore/atpstoreRead.scala"
    }

    provisioner "file" {
        source = "./gatling-home/run.sh"
        destination = "${local.gatling-home}/run.sh"
    }

    provisioner "remote-exec" "change file permission" {
        inline = [
            "chmod +x ${local.gatling-home}/run.sh",
        ]
    }

    provisioner "file" {
        source = "./gatling-home/endpoints.txt"
        destination = "${local.gatling-home}/endpoints.txt"
    }

    provisioner "remote-exec" "OS tuning - 1/2" {
        inline = [
            "sudo bash -c 'echo \"*       soft    nofile  65535\" >> /etc/security/limits.conf'",
            "sudo bash -c 'echo \"*       hard    nofile  65535\" >> /etc/security/limits.conf'",
            "sudo bash -c 'echo \"session required pam_limits.so\" >> /etc/pam.d/common-session'",
            "sudo bash -c 'echo \"session required pam_limits.so\" >> /etc/pam.d/sshd'",
            "sudo bash -c 'echo \"UseLogin yes\" >> /etc/ssh/sshd_config'",
            "sudo sysctl -w net.ipv4.ip_local_port_range=\"1025 65535\"",
            "echo 300000 | sudo tee /proc/sys/fs/nr_open",
            "echo 300000 | sudo tee /proc/sys/fs/file-max",
        ]
    }

    provisioner "remote-exec" "OS tuning - 2/2" {
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
  value = ["${oci_core_instance.loadtester.public_ip}"]
}

output "loadtester-private-key-pem" {
  value = ["${tls_private_key.loadtester-ssh-key-pair.private_key_pem}"]
}