using JuMP
PMs = PowerModels
TESTLOG = Memento.getlogger(PowerModels)

@testset "test multinetwork" begin

    @testset "idempotent unit transformation" begin
        @testset "5-bus replicate case" begin
            mn_data = build_mn_data("../test/data/matpower/case5_dc.m")
            PowerModels.make_mixed_units!(mn_data)
            PowerModels.make_per_unit!(mn_data)

            @test InfrastructureModels.compare_dict(mn_data, build_mn_data("../test/data/matpower/case5_dc.m"))
        end
        @testset "14+24 hybrid case" begin
            mn_data = build_mn_data("../test/data/matpower/case14.m", "../test/data/matpower/case24.m")
            PowerModels.make_mixed_units!(mn_data)
            PowerModels.make_per_unit!(mn_data)

            @test InfrastructureModels.compare_dict(mn_data, build_mn_data("../test/data/matpower/case14.m", "../test/data/matpower/case24.m"))
        end
    end


    @testset "topology processing" begin
        @testset "7-bus replicate status case" begin
            mn_data = build_mn_data("../test/data/matpower/case7_tplgy.m")
            PowerModels.propagate_topology_status!(mn_data)

            active_buses = Set(["2", "4", "5", "7"])
            active_branches = Set(["8"])
            active_dclines = Set(["3"])

            for (i,nw_data) in mn_data["nw"]
                for (i,bus) in nw_data["bus"]
                    if i in active_buses
                        @test bus["bus_type"] != 4
                    else
                        @test bus["bus_type"] == 4
                    end
                end

                for (i,branch) in nw_data["branch"]
                    if i in active_branches
                        @test branch["br_status"] == 1
                    else
                        @test branch["br_status"] == 0
                    end
                end

                for (i,dcline) in nw_data["dcline"]
                    if i in active_dclines
                        @test dcline["br_status"] == 1
                    else
                        @test dcline["br_status"] == 0
                    end
                end
            end
        end
        @testset "7-bus replicate filer case" begin
            mn_data = build_mn_data("../test/data/matpower/case7_tplgy.m")
            PowerModels.propagate_topology_status!(mn_data)
            PowerModels.select_largest_component!(mn_data)

            active_buses = Set(["4", "5", "7"])
            active_branches = Set(["8"])
            active_dclines = Set(["3"])

            for (i,nw_data) in mn_data["nw"]
                for (i,bus) in nw_data["bus"]
                    if i in active_buses
                        @test bus["bus_type"] != 4
                    else
                        @test bus["bus_type"] == 4
                    end
                end

                for (i,branch) in nw_data["branch"]
                    if i in active_branches
                        @test branch["br_status"] == 1
                    else
                        @test branch["br_status"] == 0
                    end
                end

                for (i,dcline) in nw_data["dcline"]
                    if i in active_dclines
                        @test dcline["br_status"] == 1
                    else
                        @test dcline["br_status"] == 0
                    end
                end
            end
        end
        @testset "7+14 hybrid filer case" begin
            mn_data = build_mn_data("../test/data/matpower/case7_tplgy.m", "../test/data/matpower/case14.m")
            PowerModels.propagate_topology_status!(mn_data)
            PowerModels.select_largest_component!(mn_data)

            case7_data = mn_data["nw"]["1"]
            case14_data = mn_data["nw"]["2"]

            case7_active_buses = Dict(x for x in case7_data["bus"] if x.second["bus_type"] != 4)
            case14_active_buses = Dict(x for x in case14_data["bus"] if x.second["bus_type"] != 4)

            @test length(case7_active_buses) == 3
            @test length(case14_active_buses) == 14
        end
    end

    @testset "2 period 5-bus asymmetric case" begin
        mn_data = build_mn_data("../test/data/matpower/case5_asym.m")


        @testset "test dc polar opb" begin
            result = PowerModels._run_mn_opb(mn_data, DCPPowerModel, ipopt_solver)

            @test result["termination_status"] == LOCALLY_SOLVED
            @test isapprox(result["objective"], 29620.0; atol = 1e0)
            @test isapprox(
                result["solution"]["nw"]["1"]["gen"]["2"]["pg"],
                result["solution"]["nw"]["2"]["gen"]["2"]["pg"];
                atol = 1e-3
            )
            @test isapprox(
                result["solution"]["nw"]["1"]["gen"]["4"]["pg"],
                result["solution"]["nw"]["2"]["gen"]["4"]["pg"];
                atol = 1e-3
            )
        end


        @testset "test ac polar opf" begin
            result = PowerModels.run_mn_opf(mn_data, ACPPowerModel, ipopt_solver)

            @test result["termination_status"] == LOCALLY_SOLVED
            @test isapprox(result["objective"], 35103.8; atol = 1e0)
            @test isapprox(
                result["solution"]["nw"]["1"]["gen"]["2"]["pg"],
                result["solution"]["nw"]["2"]["gen"]["2"]["pg"];
                atol = 1e-3
            )
            @test isapprox(
                result["solution"]["nw"]["1"]["gen"]["4"]["pg"],
                result["solution"]["nw"]["2"]["gen"]["4"]["pg"];
                atol = 1e-3
            )
        end

        @testset "test dc polar opf" begin
            result = PowerModels.run_mn_opf(mn_data, DCPPowerModel, ipopt_solver)

            @test result["termination_status"] == LOCALLY_SOLVED
            @test isapprox(result["objective"], 34959.8; atol = 1e0)
            @test isapprox(
                result["solution"]["nw"]["1"]["gen"]["2"]["pg"],
                result["solution"]["nw"]["2"]["gen"]["2"]["pg"];
                atol = 1e-3
            )
            @test isapprox(
                result["solution"]["nw"]["1"]["gen"]["4"]["pg"],
                result["solution"]["nw"]["2"]["gen"]["4"]["pg"];
                atol = 1e-3
            )
        end

        @testset "test soc opf" begin
            result = PowerModels.run_mn_opf(mn_data, SOCWRPowerModel, ipopt_solver)

            @test result["termination_status"] == LOCALLY_SOLVED
            @test isapprox(result["objective"], 29999.4; atol = 1e0)
            @test isapprox(
                result["solution"]["nw"]["1"]["gen"]["2"]["pg"],
                result["solution"]["nw"]["2"]["gen"]["2"]["pg"];
                atol = 1e-3
            )
            @test isapprox(
                result["solution"]["nw"]["1"]["gen"]["4"]["pg"],
                result["solution"]["nw"]["2"]["gen"]["4"]["pg"];
                atol = 1e-3
            )
        end

        @testset "test nfa opf" begin
            result = PowerModels.run_mn_opf(mn_data, NFAPowerModel, ipopt_solver)

            @test result["termination_status"] == LOCALLY_SOLVED
            @test isapprox(result["objective"], 29620.0; atol = 1e0)
            @test isapprox(
                result["solution"]["nw"]["1"]["gen"]["2"]["pg"],
                result["solution"]["nw"]["2"]["gen"]["2"]["pg"];
                atol = 1e-3
            )
            @test isapprox(
                result["solution"]["nw"]["1"]["gen"]["4"]["pg"],
                result["solution"]["nw"]["2"]["gen"]["4"]["pg"];
                atol = 1e-3
            )
        end
    end

    @testset "2 period 5-bus dual variable case" begin
        mn_data = build_mn_data("../test/data/matpower/case5.m")

        @testset "test dc polar opf" begin
            result = PowerModels.run_mn_opf(mn_data, DCPPowerModel, ipopt_solver, setting = Dict("output" => Dict("duals" => true)))

            @test result["termination_status"] == LOCALLY_SOLVED
            @test isapprox(result["objective"], 35226.4; atol = 1e0)

            for (i,nw_data) in result["solution"]["nw"]
                for (i, bus) in nw_data["bus"]
                    @test haskey(bus, "lam_kcl_r")
                    @test bus["lam_kcl_r"] >= -4000 && bus["lam_kcl_r"] <= 0
                    @test haskey(bus, "lam_kcl_i")
                    @test isnan(bus["lam_kcl_i"])
                end
                for (i, branch) in nw_data["branch"]
                    @test haskey(branch, "mu_sm_fr")
                    @test branch["mu_sm_fr"] >= -1 && branch["mu_sm_fr"] <= 6000
                    @test haskey(branch, "mu_sm_to")
                    @test isapprox(branch["mu_sm_to"], 0.0; atol = 1e-2)
                end
            end
        end
    end


    @testset "hybrid network case - polar" begin
        mn_data = build_mn_data("../test/data/matpower/case14.m", "../test/data/matpower/case24.m")

        @testset "test ac polar opf" begin
            result = PowerModels.run_mn_opf(mn_data, ACPPowerModel, ipopt_solver)

            @test result["termination_status"] == LOCALLY_SOLVED
            @test isapprox(result["objective"], 87886.5; atol = 1e0)
        end

        @testset "test ac rectangular opf" begin
            result = PowerModels.run_mn_opf(mn_data, ACRPowerModel, ipopt_solver)

            @test result["termination_status"] == LOCALLY_SOLVED
            @test isapprox(result["objective"], 87886.5; atol = 1e0)
        end

        @testset "test soc opf" begin
            result = PowerModels.run_mn_opf(mn_data, SOCWRPowerModel, ipopt_solver)

            @test result["termination_status"] == LOCALLY_SOLVED
            @test isapprox(result["objective"], 78765.8; atol = 1e0)
        end
    end


    @testset "opf with storage case" begin
        mn_data = build_mn_data("../test/data/matpower/case5_strg.m", replicates=4)

        @testset "test ac polar opf" begin
            result = PowerModels.run_mn_opf_strg(mn_data, PowerModels.ACPPowerModel, juniper_solver)

            @test result["termination_status"] == LOCALLY_SOLVED
            @test isapprox(result["objective"], 70435.5; atol = 1e0)


            @test isapprox(result["solution"]["nw"]["1"]["storage"]["1"]["ps"], -0.0447822; atol = 1e-3)
            @test isapprox(result["solution"]["nw"]["1"]["storage"]["1"]["qs"],  0.0000000; atol = 1e-3)
            @test isapprox(result["solution"]["nw"]["1"]["storage"]["2"]["ps"], -0.079233; atol = 1e-3)
            @test isapprox(result["solution"]["nw"]["1"]["storage"]["2"]["qs"],  0.0000000; atol = 1e-3)

            @test isapprox(result["solution"]["nw"]["2"]["storage"]["1"]["ps"], -0.0447822; atol = 1e-3)
            @test isapprox(result["solution"]["nw"]["2"]["storage"]["1"]["qs"],  0.0000000; atol = 1e-3)
            @test isapprox(result["solution"]["nw"]["2"]["storage"]["2"]["ps"], -0.079233; atol = 1e-3)
            @test isapprox(result["solution"]["nw"]["2"]["storage"]["2"]["qs"],  0.0000000; atol = 1e-3)

            @test isapprox(result["solution"]["nw"]["3"]["storage"]["1"]["ps"], -0.0447824; atol = 1e-3)
            @test isapprox(result["solution"]["nw"]["3"]["storage"]["1"]["qs"],  0.0000000; atol = 1e-3)
            @test isapprox(result["solution"]["nw"]["3"]["storage"]["2"]["ps"],  0.0000000; atol = 1e-3)
            @test isapprox(result["solution"]["nw"]["3"]["storage"]["2"]["qs"],  0.0000000; atol = 1e-3)

            @test isapprox(result["solution"]["nw"]["4"]["storage"]["1"]["ps"], -0.0447822; atol = 1e-3)
            @test isapprox(result["solution"]["nw"]["4"]["storage"]["1"]["qs"],  0.0000000; atol = 1e-3)
            @test isapprox(result["solution"]["nw"]["4"]["storage"]["2"]["ps"], -0.079233; atol = 1e-3)
            @test isapprox(result["solution"]["nw"]["4"]["storage"]["2"]["qs"],  0.0000000; atol = 1e-3)

        end

        @testset "test soc opf" begin
            result = PowerModels.run_mn_opf_strg(mn_data, PowerModels.SOCWRPowerModel, juniper_solver)

            @test result["termination_status"] == LOCALLY_SOLVED
            @test isapprox(result["objective"], 58853.5; atol = 1e0)

            @test isapprox(result["solution"]["nw"]["1"]["storage"]["1"]["ps"], -0.0597052; atol = 1e-3)
            @test isapprox(result["solution"]["nw"]["1"]["storage"]["1"]["qs"],  0.0000000; atol = 1e-3)
            @test isapprox(result["solution"]["nw"]["1"]["storage"]["2"]["ps"], -0.0596959; atol = 1e-3)
            @test isapprox(result["solution"]["nw"]["1"]["storage"]["2"]["qs"],  0.0000000; atol = 1e-3)

            @test isapprox(result["solution"]["nw"]["2"]["storage"]["1"]["ps"], -0.0597053; atol = 1e-3)
            @test isapprox(result["solution"]["nw"]["2"]["storage"]["1"]["qs"],  0.0000000; atol = 1e-3)
            @test isapprox(result["solution"]["nw"]["2"]["storage"]["2"]["ps"], -0.0596960; atol = 1e-3)
            @test isapprox(result["solution"]["nw"]["2"]["storage"]["2"]["qs"],  0.0000000; atol = 1e-3)

            @test isapprox(result["solution"]["nw"]["3"]["storage"]["1"]["ps"], -0.0597056; atol = 1e-3)
            @test isapprox(result["solution"]["nw"]["3"]["storage"]["1"]["qs"],  0.0000000; atol = 1e-3)
            @test isapprox(result["solution"]["nw"]["3"]["storage"]["2"]["ps"], -0.0596961; atol = 1e-3)
            @test isapprox(result["solution"]["nw"]["3"]["storage"]["2"]["qs"],  0.0000000; atol = 1e-3)

            @test isapprox(result["solution"]["nw"]["4"]["storage"]["1"]["ps"],  0.0000000; atol = 1e-3)
            @test isapprox(result["solution"]["nw"]["4"]["storage"]["1"]["qs"],  0.0000000; atol = 1e-3)
            @test isapprox(result["solution"]["nw"]["4"]["storage"]["2"]["ps"], -0.0596964; atol = 1e-3)
            @test isapprox(result["solution"]["nw"]["4"]["storage"]["2"]["qs"],  0.0000000; atol = 1e-3)
        end

        @testset "test dc polar opf" begin
            for (n, net) in mn_data["nw"]
                for (i, gen) in net["gen"]
                    gen["cost"]= prepend!(gen["cost"], 0.01)
                end
            end

            result = PowerModels.run_mn_opf_strg(mn_data, PowerModels.DCPPowerModel, juniper_solver)

            @test result["termination_status"] == LOCALLY_SOLVED
            @test isapprox(result["objective"], 69703.10; atol = 1e0)

            @test isapprox(sum(network["storage"]["1"]["ps"] for (n, network) in result["solution"]["nw"]), -0.180000; atol=1e-3)
            @test isapprox(sum(network["storage"]["2"]["ps"] for (n, network) in result["solution"]["nw"]), -0.240000; atol=1e-3)
        end

        @testset "storage constraint warning" begin
            for (n,network) in mn_data["nw"]
                delete!(network, "time_elapsed")
            end

            mn_data["nw"]["1"]["storage"]["1"]["status"] = 0  # verify that storage activation does not cause error

            Memento.setlevel!(TESTLOG, "warn")
            @test_warn(TESTLOG, "network data should specify time_elapsed, using 1.0 as a default", PowerModels.run_mn_opf_strg(mn_data, PowerModels.ACPPowerModel, juniper_solver))
            Memento.setlevel!(TESTLOG, "error")
        end
    end


    @testset "test solution feedback" begin
        mn_data = build_mn_data("../test/data/matpower/case5_asym.m")

        opf_result = PowerModels.run_mn_opf(mn_data, ACPPowerModel, ipopt_solver)
        @test opf_result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(opf_result["objective"], 35103.8; atol = 1e0)

        PowerModels.update_data!(mn_data, opf_result["solution"])

        pf_result = PowerModels._run_mn_pf(mn_data, ACPPowerModel, ipopt_solver)
        @test pf_result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(pf_result["objective"], 0.0; atol = 1e-3)

        for (n, nw_data) in mn_data["nw"]
            #println(n)
            for (i,bus) in nw_data["bus"]
                #println(opf_result["solution"]["nw"][n]["bus"][i]["va"])
                #println(pf_result["solution"]["nw"][n]["bus"][i]["va"])
                #println()

                @test isapprox(opf_result["solution"]["nw"][n]["bus"][i]["va"], pf_result["solution"]["nw"][n]["bus"][i]["va"]; atol = 1e-3)
                @test isapprox(opf_result["solution"]["nw"][n]["bus"][i]["vm"], pf_result["solution"]["nw"][n]["bus"][i]["vm"]; atol = 1e-3)
            end

            for (i,gen) in nw_data["gen"]
                @test isapprox(opf_result["solution"]["nw"][n]["gen"][i]["pg"], pf_result["solution"]["nw"][n]["gen"][i]["pg"]; atol = 1e-3)
                # cannot check this value solution does not appeat to be unique; verify this!
                #@test isapprox(opf_result["solution"]["gen"][i]["qg"], pf_result["solution"]["gen"][i]["qg"]; atol = 1e-3)
            end

            for (i,dcline) in nw_data["dcline"]
                @test isapprox(opf_result["solution"]["nw"][n]["dcline"][i]["pf"], pf_result["solution"]["nw"][n]["dcline"][i]["pf"]; atol = 1e-3)
                @test isapprox(opf_result["solution"]["nw"][n]["dcline"][i]["pt"], pf_result["solution"]["nw"][n]["dcline"][i]["pt"]; atol = 1e-3)
            end
        end

    end

    @testset "test errors and warnings" begin
        mn_data = build_mn_data("../test/data/matpower/case5.m")

        @test_throws(TESTLOG, ErrorException, PowerModels.correct_voltage_angle_differences!(mn_data))
        @test_throws(TESTLOG, ErrorException, PowerModels.correct_thermal_limits!(mn_data))
        @test_throws(TESTLOG, ErrorException, PowerModels.correct_branch_directions!(mn_data))
        @test_throws(TESTLOG, ErrorException, PowerModels.check_branch_loops(mn_data))
        @test_throws(TESTLOG, ErrorException, PowerModels.check_connectivity(mn_data))
        @test_throws(TESTLOG, ErrorException, PowerModels.correct_transformer_parameters!(mn_data))
        @test_throws(TESTLOG, ErrorException, PowerModels.correct_bus_types!(mn_data))
        @test_throws(TESTLOG, ErrorException, PowerModels.correct_dcline_limits!(mn_data))
        @test_throws(TESTLOG, ErrorException, PowerModels.check_voltage_setpoints(mn_data))
        @test_throws(TESTLOG, ErrorException, PowerModels.correct_cost_functions!(mn_data))
        @test_throws(TESTLOG, ErrorException, PowerModels.calc_connected_components(mn_data))

        Memento.setlevel!(TESTLOG, "warn")
        @test_nowarn PowerModels.correct_reference_buses!(mn_data)
        @test_nowarn PowerModels.make_multiconductor!(mn_data, 3)
        @test_nowarn PowerModels.check_conductors(mn_data)
        Memento.setlevel!(TESTLOG, "error")

        @test_throws(TESTLOG, ErrorException, PowerModels.run_ac_opf(mn_data, ipopt_solver))
    end

end
