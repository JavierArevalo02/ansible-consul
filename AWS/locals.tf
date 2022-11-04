locals { 
nsgrules = {
   
    ssh = {
        type              = "ingress"
        from_port         = 22
        to_port           = 22
        protocol          = "tcp"
        cidr_blocks       = ["129.151.110.163/32"]
    }
    
    http = {
        type              = "ingress"
        from_port         = 80
        to_port           = 80
        protocol          = "tcp"
        cidr_blocks       = ["0.0.0.0/0"]
    }
  }
 
}