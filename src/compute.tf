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
    instance_image_ocid = {
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
        source_id   = "${local.instance_image_ocid["eu-frankfurt-1"]}"
    }

    extended_metadata = {
        ssh_authorized_keys = "${tls_private_key.loadtester-ssh-key-pair.public_key_openssh}"
    }

    # connection {
    #     type        = "ssh"
    #     host        = "${self.public_ip}"
    #     user        = "opc"
    #     private_key = "${file(var.core_instance_ssh_private_key_file)}"
    # }

    # provisioner "remote-exec" "install jdk & gatling" {
    #     inline = [
    #         #"sudo yum -y update",
    #         "sudo yum -y install java-1.8.0-openjdk",
    #         "wget https://repo1.maven.org/maven2/io/gatling/highcharts/gatling-charts-highcharts-bundle/3.0.1.1/gatling-charts-highcharts-bundle-3.0.1.1-bundle.zip -O /tmp/gatling-charts-highcharts-bundle-3.0.1.1-bundle.zip",
    #         "mkdir ~/gatling",
    #         "unzip /tmp/gatling-charts-highcharts-bundle-3.0.1.1-bundle.zip -d ~/gatling",
    #     ]
    # }

    # provisioner "remote-exec" "preparation for copying files" {
    #     inline = [
    #         "mkdir ~/gatling/gatling-charts-highcharts-bundle-3.0.1.1/user-files/simulations/atpstore",
    #     ]
    # }

    # provisioner "file" {
    #     source = "./gatling-home/simulations/atpstore/atpstoreRead.scala"
    #     destination = "/home/opc/gatling/gatling-charts-highcharts-bundle-3.0.1.1/user-files/simulations/atpstore/atpstoreRead.scala"
    # }

    # provisioner "file" {
    #     source = "./gatling-home/run.sh"
    #     destination = "/home/opc/gatling/gatling-charts-highcharts-bundle-3.0.1.1/run.sh"
    # }

    # provisioner "file" {
    #     source = "./gatling-home/endpoints.txt"
    #     destination = "/home/opc/gatling/gatling-charts-highcharts-bundle-3.0.1.1/endpoints.txt"
    # }

    # provisioner "remote-exec" "change file permission" {
    #     inline = [
    #         "chmod +x /home/opc/gatling/gatling-charts-highcharts-bundle-3.0.1.1/run.sh",
    #     ]
    # }
}

output "loadtester-public-ip" {
  value = ["${oci_core_instance.loadtester.public_ip}"]
}

output "loadtester-private-key-pem" {
  value = ["${tls_private_key.loadtester-ssh-key-pair.private_key_pem}"]
}