## Part A Questions

1.What is Infrastructure as Code, and which problems of manually created infrastructure does it solve?
    Infrastructure as Code (IaC) is the practice of defining and managing infrastructure using machine-readable configuration files instead of creating and configuring resources manually through a graphical interface. The code describes resources such as virtual machines, networks, security groups and IP addresses, and an IaC tool such as OpenTofu can use this description to create and manage the actual infrastructure. One of the main problems IaC solves is repeatability. In Week 1, I created my VM manually through the cPouta web interface and then logged in over SSH to install Apache and configure the web page. This works, but if I needed to create the same server again, I would have to remember and repeat all the steps. It would also be easy to accidentally configure the second server differently from the first one. With OpenTofu, the infrastructure is described in files such as main.tf, and cloud-init describes how the VM should configure itself when it starts. I can therefore run tofu apply to create the environment again and tofu destroy to remove it. IaC also makes infrastructure changes easier to review and reproduce because the configuration can be stored in Git. Instead of manually remembering that my web server needs TCP ports 22 and 80, the security group rules are explicitly defined in main.tf. This makes the desired configuration visible and easier to reproduce.

2.Explain the difference between declarative and imperative infrastructure automation. What does idempotency mean, and why is it important?
    Declarative and imperative automation differ in how they describe the desired operation. Imperative automation gives a sequence of instructions that should be executed, while declarative automation describes the desired final state and allows the automation tool to determine what actions are necessary to reach that state. For example, installing Apache manually over SSH is relatively imperative. I might run apt update, install the apache2 package, create an HTML file and start the service. I am explicitly telling the system which steps to perform. In contrast, my OpenTofu configuration declares that a VM, a security group, a network port and a floating IP should exist. OpenTofu compares this desired configuration with its current state and determines which resources need to be created, changed or destroyed. Idempotency means that repeatedly applying the same configuration should produce the same desired state rather than continuously making additional changes. This is important for IaC because I should be able to run tofu apply again after the infrastructure already exists without recreating everything unnecessarily. After my Week 7 VM has been created correctly, running tofu plan should normally show no changes if neither the configuration nor the real infrastructure has changed. This makes automated infrastructure safer and more predictable.

3.Why was OpenTofu created? Compare Terraform and OpenTofu — would the choice between them matter to you as a developer, or to a company?
    OpenTofu was created as a community-driven fork of Terraform after HashiCorp changed Terraform's license from the Mozilla Public License 2.0 (MPL 2.0) to the Business Source License (BSL) in 2023. The change created concerns among parts of the Terraform community about how the project could be used and developed, particularly by companies building competing products. OpenTofu was created under the Linux Foundation as an open-source alternative that continues the Terraform-style infrastructure-as-code workflow. For a developer, OpenTofu and Terraform are similar in many important ways. They use the same general configuration language and concepts such as providers, resources, variables, state and plans. This means that knowledge of one is useful when working with the other. However, there can be differences in supported features, provider versions and ecosystem tooling, so they should not simply be assumed to be identical forever. For a company, the choice can matter more because licensing, long-term project governance and ecosystem support can affect technology decisions. A company that wants a fully open-source project with community governance might prefer OpenTofu, while another company might choose Terraform because of its existing tooling, support contracts or ecosystem. So I would not choose between them only based on syntax. I would also consider licensing, compatibility, support and the existing infrastructure of the organization.

4.What is the state file used for? Why should it not be committed to a Git repository, and how do teams usually share it instead?
    The state file is used to keep track of the infrastructure that OpenTofu manages. It records information about resources that have been created and provides OpenTofu with a representation of the infrastructure it is responsible for. This allows OpenTofu to compare the configuration, its recorded state and the real infrastructure when creating a plan. The state file should not normally be committed to a Git repository because it can contain sensitive or infrastructure-specific information. More importantly, using a local state file in a team can cause problems if several people modify it independently. Two different developers could make changes based on different versions of the state, which could lead to conflicts or incorrect plans. Teams commonly store state in a remote backend that provides shared access and, depending on the backend, locking and versioning. This allows multiple team members or CI/CD systems to work with the same state rather than keeping separate local copies. The Week 7 drift experiment demonstrates why state matters. When I manually deleted the HTTP security group rule, OpenTofu could detect that a resource it manages was missing and planned to recreate it. In contrast, a manually added rule that was not part of my OpenTofu configuration was not necessarily treated as a resource that OpenTofu should remove. This shows that OpenTofu's management is based on the resources described and tracked by its configuration and state, rather than simply taking control of every object in the OpenStack project.

## Part B Exercise

Experiment 1: Change
    Option A – Change Page Message
        Prediction: 
            I predicted that changing `page_message` would cause the VM to be destroyed and recreated.
            Because `page_message` is passed into `cloud-init.yaml` through `templatefile()` and becomes part of the VM's `user_data`. Cloud-init mainly uses this configuration during the VM's initial boot.
        Result:
            After changing `page_message`, I ran `tofu plan`, the plan showed that the VM would be replaced.
        Explanation:
            The VM was replaced because the change affected `user_data`. The new user data cannot simply be applied to the already running VM in the same way as a normal security group rule change. After the VM was recreated, the floating IP was same. This happened because the floating IP is a separate resource attached to the network port.

    Option B - added https rule
        Prediction:
            I predicted that adding the HTTPS security group rule would add one resource. I did not expect the VM to be changed or replaced because the new rule is a separate security group rule resource.
        Result:
            The HTTPS security group rule was added successfully. The VM was not recreated.
        Explanation:
            This result was different from Option A, since changing page_message affected the VM's user_data, which caused the VM to be replaced. In contrast, the HTTPS rule is an independent security group rule resource, so OpenTofu could create it without recreating the VM.
            Opening TCP port 443 does not automatically enable HTTPS. The security group now allows HTTPS traffic to reach the server, but Apache still needs to be configured for HTTPS and a TLS certificate must be available. Therefore, simply adding the firewall rule does not necessarily make https work.

Experiment 2: Drift

2.1 Delete the HTTP Rule
    Prediction: 
        I predicted that OpenTofu would detect that the HTTP rule was missing because the rule is declared as an OpenTofu resource.
    Result:
        I manually deleted the TCP port 80 rule from the cPouta web interface. The web page stopped loading. Then I ran `tofu plan`, the plan detected the missing rule and proposed recreating it.
    Explanation:
        The configuration still declared the HTTP rule, while the real infrastructure no longer contained it. So there was a difference between the desired configuration and the actual infrastructure. OpenTofu detected this drift and planned to restore the rule. After running `tofu apply`, the HTTP rule was created again and the web page became accessible.

2.2 Add a Manual Rule
    Prediction:
        I predicted that OpenTofu would treat the manually added port rule differently because this rule was not declared in my configuration.
    Result:
        As the prediction, it treat the rule differently, but not remove it.
    Explanation:
        The result shows that OpenTofu primarily manages resources represented by its configuration and state. A resource that exists in OpenStack but is not declared as an OpenTofu resource is not automatically treated as something that OpenTofu must remove. This demonstrates why manual changes should generally be avoided in infrastructure managed by IaC. Manual changes can create differences between the documented configuration and the real infrastructure.

Experiment 3 — Destroy and Re-create
    Prediction:
        I expected `tofu destroy` to remove the resources managed by OpenTofu, including the VM, security group, network port, SSH key pair and floating IP. And I did not expect the existing project network to be destroyed because it is referenced through a data source rather than managed as a resource. I expected the resources to be destroyed according to their dependencies.
    Result:
        I ran `tofu destroy`, the resources were successfully removed. Then I ran `tofu apply`, The infrastructure was successfully recreated as before. The IP address changed after the rebuild.
    Explanation:
        The destroy order was determined by the dependencies between the resources. The VM also uses the port through its network configuration. OpenTofu uses these references to construct a dependency graph and uses that graph when creating and destroying resources.
        The project network survived because it was not created by my OpenTofu configuration. It is represented by a data source.
        A data source looks up an existing resource but does not manage its lifecycle. So tofu destroy removed the resources created by my configuration but did not remove the existing project network.
        The IP is exposed through an OpenTofu output, so I do not need to hard-code the address in my workflow. After rebuilding the infrastructure, I can run tofu output and obtain the current address and URL. If the IP address had to remain stable, I would need to preserve and reuse a specific floating IP instead of destroying it and allocating a new one during every rebuild.
        The initial IaC setup took longer because I had to write and debug the configuration, but once the configuration was working, rebuilding the server was much easier and more repeatable.