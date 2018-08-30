using DataStructures
using LinearAlgebraicRepresentation
using LARVIEW
Lar = LinearAlgebraicRepresentation
View = LARVIEW.view


###  2D triangulation
##################################################################
""" 
	obj2lar2D(path::AbstractString)::LinearAlgebraicRepresentation.LARmodel

Read a *triangulation* from file, given its `path`. Return a `LARmodel` object
"""
function obj2lar2D(path::AbstractString)::LinearAlgebraicRepresentation.LARmodel
    vs = Array{Float64, 2}(0, 3)
    edges = Array{Array{Int, 1}, 1}()
    faces = Array{Array{Int, 1}, 1}()

    open(path, "r") do fd
		for line in eachline(fd)
			elems = split(line)
			if length(elems) > 0
				if elems[1] == "v"
					x = parse(Float64, elems[2])
					y = parse(Float64, elems[3])
					z = parse(Float64, elems[4])
					vs = [vs; x y z]
				elseif elems[1] == "f"
					# Ignore the vertex tangents and normals
					_,v1,v2,v3 = map(parse, elems)
					append!(edges, map(sort,[[v1,v2],[v2,v3],[v3,v1]]))
					push!(faces, [v1, v2, v3])
				end
				edges = collect(Set(edges))
			end
		end
	end
    return (vs, [edges,faces])::LinearAlgebraicRepresentation.LARmodel
end


""" 
	lar2obj2D(V::LinearAlgebraicRepresentation.Points, 
			cc::LinearAlgebraicRepresentation.ChainComplex)::String

Produce a *triangulation* from a `LARmodel`. Return a `String` object
"""
function lar2obj2D(V::LinearAlgebraicRepresentation.Points, cc::LinearAlgebraicRepresentation.ChainComplex)::String
    assert(length(cc) == 2)
    copEV, copFE = cc
    V = [V zeros(size(V, 1))]

    obj = ""
    for v in 1:size(V, 1)
        obj = string(obj, "v ", 
        	round(V[v, 1], 6), " ", 
        	round(V[v, 2], 6), " ", 
        	round(V[v, 3], 6), "\n")
    end

    print("Triangulating")
    triangulated_faces = triangulate2D(V, cc[1:2])
    println("DONE")

	obj = string(obj, "\n")
	for f in 1:copFE.m
		triangles = triangulated_faces[f]
		for tri in triangles
			t = tri
			#t = copCF[c, f] > 0 ? tri : tri[end:-1:1]
			obj = string(obj, "f ", t[1], " ", t[2], " ", t[3], "\n")
		end
	end

    return obj
end


""" 
	triangulate2D(V::LinearAlgebraicRepresentation.Points, 
			cc::LinearAlgebraicRepresentation.ChainComplex)::Array{Any, 1}

Compute a *CDT* for each face of a `ChainComplex`. Return an `Array` of triangles.
"""
function triangulate2D(V::LinearAlgebraicRepresentation.Points, cc::LinearAlgebraicRepresentation.ChainComplex)::Array{Any, 1}
    copEV, copFE = cc
    triangulated_faces = Array{Any, 1}(copFE.m)
	
    for f in 1:copFE.m       
        edges_idxs = copFE[f, :].nzind
        edge_num = length(edges_idxs)
        edges = Array{Int64,1}[] #zeros(Int64, edge_num, 2)

        fv = LinearAlgebraicRepresentation.buildFV(copEV, copFE[f, :])
        vs = V[fv, :]
        
        for i in 1:length(fv)
        	edge = Int64[0,0]
            edge[1] = fv[i]
            edge[2] = i == length(fv) ? fv[1] : fv[i+1]
            push!(edges,edge::Array{Int64,1})
        end
        edges = hcat(edges...)'
        
        triangulated_faces[f] = Triangle.constrained_triangulation(
        vs, fv, edges, fill(true, edge_num))
        tV = V[:, 1:2]
        
        area = LinearAlgebraicRepresentation.face_area(tV, copEV, copFE[f, :])
        if area < 0 
            for i in 1:length(triangulated_faces[f])
                triangulated_faces[f][i] = triangulated_faces[f][i][end:-1:1]
            end
        end
    end

    return triangulated_faces
end


###	Unit test:  to insert in test/utilities.jl
#####################################################################


###	Dati:  complesso 1D immerso in 2D 
#####################################################################

V = [732.725 1123.87 1123.87 1124.49 1124.49 776.005 776.005 731.819 731.819 732.725 732.725 732.725 1284.06 1592.17 1592.17 1592.32 1592.32 1281.66 1281.66 1284.06 1284.06 1284.06 789.106 789.236 789.236 1030.28 1030.28 1031.02 1031.02 789.106 789.106 789.106 734.892 1087.13 1087.13 1087.63 1087.63 1227.73 1227.73 1226.84 1226.84 1648.35 1648.35 1649.66 1649.66 1591.08 1591.08 1590.19 1590.19 1469.27 1469.27 1470.21 1470.21 1414.42 1414.42 1412.64 1412.64 1178.75 1178.75 1179.1 1179.1 1123.36 1123.36 1123.49 1123.49 677.788 677.788 677.027 677.027 736.012 736.012 734.892 734.892 734.892 692.591 692.119 692.119 710.549 710.549 748.971 748.971 748.398 748.398 774.963 774.963 773.044 773.044 1046.13 1046.13 1046.3 1046.3 1073.16 1073.16 1075.13 1075.13 1240.87 1240.87 1239.87 1239.87 1266.97 1266.97 1266.83 1266.83 1606.23 1606.23 1605.59 1605.59 1632.89 1632.89 1634.74 1634.74 1608.8 1608.8 1605.94 1605.94 1455.92 1455.92 1456.28 1456.28 1431.23 1431.23 1428.3 1428.3 1163.49 1163.49 1164.92 1164.92 1138.7 1138.7 1136.96 1136.96 934.882 934.882 775.749 775.749 776.12 776.12 761.45 761.45 718.072 718.072 719.533 719.533 1137.14 1137.14 1137.32 1137.32 719.091 719.091 719.221 719.221 692.591 692.591 692.591 776.005 1047.47 1047.47 1046.64 1046.64 776.368 776.368 776.005 776.005 776.005 1269.2 1268.89 1268.89 1606.74 1606.74 1606.72 1606.72 1269.2 1269.2 1269.2; 781.1 782.673 782.673 1048.94 1048.94 1045.53 1045.53 1005.26 1005.26 781.1 781.1 781.1 1108.07 1106.08 1106.08 1174.09 1174.09 1172.27 1172.27 1108.07 1108.07 1108.07 1106.08 1288.98 1288.98 1289.83 1289.83 1106.9 1106.9 1106.08 1106.08 1106.08 1349.71 1349.71 1349.71 1107.42 1107.42 1105.77 1105.77 1230.35 1230.35 1230.86 1230.86 615.61 615.61 615.61 615.61 1051.75 1051.75 1052.69 1052.69 615.61 615.61 615.61 615.61 1049.7 1049.7 1050.6 1050.6 615.61 615.61 615.61 615.61 726.053 726.053 726.777 726.777 1024.77 1024.77 1078.88 1078.88 1349.71 1349.71 1349.71 730.096 1024.88 1024.88 1025.99 1025.99 1067.18 1067.18 1345.41 1345.41 1345.84 1345.84 1333.11 1333.11 1333.92 1333.92 1349.71 1349.71 1347.57 1347.57 1094.47 1094.47 1093.37 1093.37 1226.19 1226.19 1226.85 1226.85 1214.78 1214.78 1215.55 1215.55 1227.84 1227.84 1227.51 1227.51 615.946 615.946 615.61 615.61 1066.73 1066.73 1067.74 1067.74 616.213 616.213 616.301 616.301 1066.68 1066.68 1065.78 1065.78 616.712 616.712 617.245 617.245 1067.13 1067.13 1064.62 1064.62 1065.23 1065.23 1057.26 1057.26 1057.24 1057.24 1011.09 1011.09 768.914 768.914 770.027 770.027 742.676 742.676 742.388 742.388 729.39 729.39 730.096 730.096 730.096 1090.67 1092.32 1092.32 1306.35 1306.35 1304.4 1304.4 1090.67 1090.67 1090.67 1093.67 1187.53 1187.53 1187.41 1187.41 1093.67 1093.67 1093.67 1093.67 1093.67]

EV = Array{Int64,1}[[1, 2], [3, 4], [5, 6], [7, 8], [9, 10], [11, 12], [13, 14], [15, 16], [17, 18], [19, 20], [21, 22], [23, 24], [25, 26], [27, 28], [29, 30], [31, 32], [33, 34], [35, 36], [37, 38], [39, 40], [41, 42], [43, 44], [45, 46], [47, 48], [49, 50], [51, 52], [53, 54], [55, 56], [57, 58], [59, 60], [61, 62], [63, 64], [65, 66], [67, 68], [69, 70], [71, 72], [73, 74], [75, 76], [77, 78], [79, 80], [81, 82], [83, 84], [85, 86], [87, 88], [89, 90], [91, 92], [93, 94], [95, 96], [97, 98], [99, 100], [101, 102], [103, 104], [105, 106], [107, 108], [109, 110], [111, 112], [113, 114], [115, 116], [117, 118], [119, 120], [121, 122], [123, 124], [125, 126], [127, 128], [129, 130], [131, 132], [133, 134], [135, 136], [137, 138], [139, 140], [141, 142], [143, 144], [145, 146], [147, 148], [149, 150], [151, 152], [153, 154], [155, 156], [157, 158], [159, 160], [161, 162], [163, 164], [165, 166], [167, 168], [169, 170], [171, 172], [173, 174]]


###	esecuzione 
#####################################################################

V,bases,coboundaries = Lar.chaincomplex(V,EV)
LARVIEW.view(V,bases[1])

ev,fv=bases
VV = [[k] for k=1:size(V,2)]
model = (V, [VV,ev,fv])
View(LARVIEW.numbering(80.)(model))

objs = lar2obj2D(V'::Lar.Points, [coboundaries...])  #va in errore
open("./villa.obj", "w") do f
	write(f, objs)
end

V,(EV,FV) = obj2lar2D("./villa.obj")

LARVIEW.view(V',EV)
LARVIEW.view(V',FV)







