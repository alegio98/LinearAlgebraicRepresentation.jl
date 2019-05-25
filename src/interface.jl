Lar = LinearAlgebraicRepresentation

"""
	characteristicMatrix( FV::Cells )::ChainOp

Binary matrix representing by rows the `p`-cells of a cellular complex.
The input parameter must be of `Cells` type. Return a sparse binary matrix,
providing the basis of a ``Chain`` space of given dimension. Notice that the
number of columns is equal to the number of vertices (0-cells).

# Example

```julia
V,(VV,EV,FV,CV) = cuboid([1.,1.,1.], true);

julia> Matrix(characteristicMatrix(FV))
6×8 Array{Int8,2}:
1  1  1  1  0  0  0  0
0  0  0  0  1  1  1  1
1  1  0  0  1  1  0  0
0  0  1  1  0  0  1  1
1  0  1  0  1  0  1  0
0  1  0  1  0  1  0  1

julia> Matrix(characteristicMatrix(CV))
1×8 Array{Int8,2}:
1  1  1  1  1  1  1  1

julia> Matrix(characteristicMatrix(EV))
12×8 Array{Int8,2}:
1  1  0  0  0  0  0  0
0  0  1  1  0  0  0  0
0  0  0  0  1  1  0  0
0  0  0  0  0  0  1  1
1  0  1  0  0  0  0  0
0  1  0  1  0  0  0  0
0  0  0  0  1  0  1  0
0  0  0  0  0  1  0  1
1  0  0  0  1  0  0  0
0  1  0  0  0  1  0  0
0  0  1  0  0  0  1  0
0  0  0  1  0  0  0  1
```
"""
function characteristicMatrix( FV::Cells )::ChainOp
	I,J,V = Int64[],Int64[],Int8[]
	for f=1:length(FV)
		for k in FV[f]
		push!(I,f)
		push!(J,k)
		push!(V,1)
		end
	end
	M_2 = sparse(I,J,V)
	return M_2
end


"""
	boundary_1( EV::Cells )::ChainOp

Computation of sparse signed boundary operator ``C_1 -> C_0``.

# Example
```julia
julia> V,(VV,EV,FV,CV) = cuboid([1.,1.,1.], true);

julia> EV
12-element Array{Array{Int64,1},1}:
[1, 2]
[3, 4]
...
[2, 6]
[3, 7]
[4, 8]

julia> boundary_1( EV::Cells )
8×12 SparseMatrixCSC{Int8,Int64} with 24 stored entries:
[1 ,  1]  =  -1
[2 ,  1]  =  1
[3 ,  2]  =  -1
...       ...
[7 , 11]  =  1
[4 , 12]  =  -1
[8 , 12]  =  1

julia> Matrix(boundary_1(EV::Cells))
8×12 Array{Int8,2}:
-1   0   0   0  -1   0   0   0  -1   0   0   0
1   0   0   0   0  -1   0   0   0  -1   0   0
0  -1   0   0   1   0   0   0   0   0  -1   0
0   1   0   0   0   1   0   0   0   0   0  -1
0   0  -1   0   0   0  -1   0   1   0   0   0
0   0   1   0   0   0   0  -1   0   1   0   0
0   0   0  -1   0   0   1   0   0   0   1   0
0   0   0   1   0   0   0   1   0   0   0   1
```
"""
function boundary_1( EV::Cells )::ChainOp
	out = characteristicMatrix(EV)'
	for e = 1:length(EV)
		out[EV[e][1],e] = -1
	end
	return out
end




"""
	coboundary_0(EV::Lar.Cells)

Return the `coboundary_0` signed operator `C_0` -> `C_1`.
"""
coboundary_0(EV::Cells) = convert(ChainOp,transpose(boundary_1(EV::Cells)))




"""
	fix_redundancy(target_mat, cscFV,cscEV)

*Fix the coboundary_1 matrix*, generated by sparse matrix product ``FV * EV^t``, for complexes with some *non-convex cells*. This approach can be used when both `EV` and `FV` of the cellular complex are known. It is exact when cells are convex. Maybe non-exact, introducing spurious incidence coefficients (``redundancies``), when adjacent faces share an edge combinatorially, but not geometrically. This happen when an edge is on the boundary of face A, but only its vertices are on the boundary of face B.  TODO: Similar situations may appear when computing algebraically CF as product of known CV and FV, with non-convex cells.

In order to remove such ``redundancies``, the Euler characteristic of 2-sphere is used, where V-E+F=2. Since we have F=2 (inner and outer face), ``V=E`` must hold, and `d=E-V` is the (non-negative) ``defect`` number, called `nfixs` in the code. It equates the number of columns `edges`
whose sum is greater than 2 for the considered row (face). Remember the in a ``d``-complex, *including* the ``outer cell``, all ``(d-1)``-faces must be shared by exactly 2 ``d``-faces. Note that `FV` *must include* the row of outer shell (exterior face).

# Example

```julia
FV = [[1,2,3,4,5,17,16,12],
[1,2,3,4,6,7,8,9,10,11,12,13,14,15],
[4,5,9,11,12,13,14,15,16,17],
[2,3,6,7], [8,9,10,11]]

FE = [[1,2,3,4,9,20,17,5],
[1,6,10,7,3,8,11,12,14,15,19,18,16,5],
[4,9,20,17,16,18,19,15,13,8],
[2,10,6,7], [11,12,13,14]]

EV = [[1,2],[2,3],[3,4],[4,5],[1,12],[2,6],[3,7],[4,9],[5,17],[6,7],[8,9],
[8,10],[9,11],[10,11],[11,15],[12,13],[12,16],[13,14],[14,15],[16,17]]

V = [0   2   5   7  10   2   5   3   7  3  7  0  3  3  7  0  10;
    16  16  16  16  16  13  13  11  11  8  8  5  5  2  2  0   0]

cscFE = u_coboundary_1( FV::Lar.Cells, EV::Lar.Cells, false);
Matrix(cscFE)
```

Notice that there are two columns (2 and 13) with 3 ones, hence (3-2)+(3-2)=2 defects to fix. The fixed complex can be shown graphically as:

```julia

VV = [[k] for k in 1:size(V,2)];
using Plasm
Plasm.view( Plasm.numbering(3)((V,[VV, EV, FV])) )
```
"""
function fix_redundancy(target_mat, cscFV,cscEV) # incidence numbers > 2#E
	nfixs = 0
	faces2fix = []
	edges2fix = []
	# target_mat and cscFV (ref_mat) should have same length per row !
	for face = 1:size(target_mat,1)
		nedges = sum(findnz(target_mat[face,:])[2])
		nverts = sum(findnz(cscFV[face,:])[2])
		if nedges != nverts
			nfixs += nedges - nverts
			#println("face $face, nedges=$nedges, nverts=$nverts")
			push!(faces2fix,face)
		end
	end
	for edge = 1:size(target_mat,2)
		nfaces = sum(findnz(target_mat[:,edge])[2])
		if nfaces > 2
			#println("edge $edge, nfaces=$nfaces")
			push!(edges2fix,edge)
		end
	end
	#println("nfixs=$nfixs")
	pairs2fix = []
	for fh in faces2fix		# for each face to fix
		for ek in edges2fix		# for each edge to fix
			if target_mat[fh, ek]==1	# edge to fix \in face to fix
				v1,v2 = findnz(cscEV[ek,:])[1]
				weight(v) = length( intersect(
							findnz(cscEV[:,v])[1], findnz(target_mat[fh,:])[1] ))
				if weight(v1)>2 && weight(v2)>2
					#println("(fh,ek) = $((fh,ek))")
					push!( pairs2fix, (fh,ek) )
				end
			end
		end
	end
	for (fh,ek) in pairs2fix
		target_mat[fh, ek] = 0
	end
	cscFE = dropzeros(target_mat)
	@assert nnz(cscFE) == 2*size(cscFE,2)
	return cscFE
end
function fix_lack(target_mat, cscFV,cscEV) # incidence numbers < 2#E
end



"""
	u_coboundary_1( FV::Lar.Cells, EV::Lar.Cells, convex=true)::Lar.ChainOp

Compute the sparse *unsigned* coboundary_1 operator ``C_1 -> C_2``.
Notice that the output matrix is `m x n`, where `m` is the number of faces, and `n`
is the number of edges.

# Examples

##  Cellular complex with convex-cells, and without outer cell

```julia
julia> V,(VV,EV,FV,CV) = Lar.cuboid([1.,1.,1.], true);

julia> u_coboundary_1(FV,EV)
6×12 SparseMatrixCSC{Int8,Int64} with 24 stored entries:
[1 ,  1]  =  1
[3 ,  1]  =  1
[1 ,  2]  =  1
[4 ,  2]  =  1
...		...
[4 , 11]  =  1
[5 , 11]  =  1
[4 , 12]  =  1
[6 , 12]  =  1

julia> Matrix(u_coboundary_1(FV,EV))
6×12 Array{Int8,2}:
1  1  0  0  1  1  0  0  0  0  0  0
0  0  1  1  0  0  1  1  0  0  0  0
1  0  1  0  0  0  0  0  1  1  0  0
0  1  0  1  0  0  0  0  0  0  1  1
0  0  0  0  1  0  1  0  1  0  1  0
0  0  0  0  0  1  0  1  0  1  0  1

julia> unsigned_boundary_2 = u_coboundary_1(FV,EV)';
```

Compute the *Unsigned* `coboundary_1` operator matrix as product of two
sparse characteristic matrices.

##  Cellular complex with non-convex cells, and with outer cell

```julia
FV = [[1,2,3,4,5,17,16,12], # outer cell
[1,2,3,4,6,7,8,9,10,11,12,13,14,15],
[4,5,9,11,12,13,14,15,16,17],
[2,3,6,7], [8,9,10,11]]

EV = [[1,2],[2,3],[3,4],[4,5],[1,12],[2,6],[3,7],[4,9],[5,17],[6,7],[8,9],
[8,10],[9,11],[10,11],[11,15],[12,13],[12,16],[13,14],[14,15],[16,17]]

out = u_coboundary_1( FV::Lar.Cells, EV::Lar.Cells, false)
```
In case of expected 2-chains with non-convex cells, instance the method with
`convex = false`, in order to fix a possible redundancy of incidence values, induced by computation through multiplication of characteristic matrices. (Look at columns
2 and 13 before, generated by default).
"""
function u_coboundary_1( FV::Lar.Cells, EV::Lar.Cells, convex=true::Bool)::Lar.ChainOp
	cscFV = Lar.characteristicMatrix(FV)
	cscEV = Lar.characteristicMatrix(EV)
	out = u_coboundary_1( cscFV::Lar.ChainOp, cscEV::Lar.ChainOp, convex::Bool)
	return out
end
function u_coboundary_1( cscFV::Lar.ChainOp, cscEV::Lar.ChainOp, convex=true::Bool)::Lar.ChainOp
	temp = cscFV * cscEV'
	I,J,Val = Int64[],Int64[],Int8[]
	for j=1:size(temp,2)
		for i=1:size(temp,1)
			if temp[i,j] == 2
				push!(I,i)
				push!(J,j)
				push!(Val,1)
			end
		end
	end
	cscFE = SparseArrays.sparse(I,J,Val)
	if !convex
		cscFE = Lar.fix_redundancy(cscFE,cscFV,cscEV)
	end
	return cscFE
end



"""
	coboundary_1( FV::Lar.Cells, EV::Lar.Cells)::Lar.ChainOp

Generate the *signed* sparse matrix of the coboundary_1 operator.
For each row, start with the first incidence number positive (i.e. assign the orientation of the first edge to the 1-cycle of the face), then bounce back and forth between vertex columns/rows of EV and FE.

# Example

julia> Matrix(cscFE)
5×20 Array{Int8,2}:
 1  1  1  1  1  0  0  0  1  0  0  0  0  0  0  0  1  0  0  1
 1  0  1  0  1  1  1  1  0  1  1  1  0  1  1  1  0  1  1  0
 0  0  0  1  0  0  0  1  1  0  0  0  1  0  1  1  1  1  1  1
 0  1  0  0  0  1  1  0  0  1  0  0  0  0  0  0  0  0  0  0
 0  0  0  0  0  0  0  0  0  0  1  1  1  1  0  0  0  0  0  0


"""
function coboundary_1( V::Lar.Points, FV::Lar.Cells, EV::Lar.Cells, convex=true::Bool, exterior=false::Bool)::Lar.ChainOp
	# generate unsigned operator's sparse matrix
	cscFV = Lar.characteristicMatrix(FV)
	cscEV = Lar.characteristicMatrix(EV)
	##if size(V,1) == 3
		##copFE = u_coboundary_1( FV::Lar.Cells, EV::Lar.Cells )
	##elseif size(V,1) == 2
		# greedy generation of incidence number signs
		copFE = coboundary_1( V, cscFV::Lar.ChainOp, cscEV::Lar.ChainOp, convex, exterior)
	##end
	return copFE
end

function coboundary_1( V::Lar.Points, cscFV::Lar.ChainOp, cscEV::Lar.ChainOp, convex=true::Bool, exterior=false::Bool )::Lar.ChainOp

	cscFE = Lar.u_coboundary_1( cscFV::Lar.ChainOp, cscEV::Lar.ChainOp, convex)
	EV = [findnz(cscEV[k,:])[1] for k=1:size(cscEV,1)]
	cscEV = sparse(Lar.coboundary_0( EV::Lar.Cells ))
	for f=1:size(cscFE,1)
		chain = findnz(cscFE[f,:])[1]	#	dense
		cycle = spzeros(Int8,cscFE.n)	#	sparse

		edge = findnz(cscFE[f,:])[1][1]; sign = 1
		cycle[edge] = sign
		chain = setdiff( chain, edge )
		while chain != []
			boundary = sparse(cycle') * cscEV
			_,vs,vals = findnz(dropzeros(boundary))

			rindex = vals[1]==1 ? vf = vs[1] : vf = vs[2]
			r_boundary = spzeros(Int8,cscEV.n)	#	sparse
			r_boundary[rindex] = 1
			r_coboundary = cscEV * r_boundary
			r_edge = intersect(findnz(r_coboundary)[1],chain)[1]
			r_coboundary = spzeros(Int8,cscEV.m)	#	sparse
			r_coboundary[r_edge] = EV[r_edge][1]<EV[r_edge][2] ? 1 : -1

			lindex = vals[1]==-1 ? vi = vs[1] : vi = vs[2]
			l_boundary = spzeros(Int8,cscEV.n)	#	sparse
			l_boundary[lindex] = -1
			l_coboundary = cscEV * l_boundary
			l_edge = intersect(findnz(l_coboundary)[1],chain)[1]
			l_coboundary = spzeros(Int8,cscEV.m)	#	sparse
			l_coboundary[l_edge] = EV[l_edge][1]<EV[l_edge][2] ? -1 : 1

			if r_coboundary != -l_coboundary  # false iff last edge
				# add edge to cycle from both sides
				rsign = rindex == EV[r_edge][1] ? 1 : -1
				lsign = lindex == EV[l_edge][2] ? -1 : 1
				cycle = cycle + rsign * r_coboundary + lsign * l_coboundary
			else
				# add last (odd) edge to cycle
				rsign = rindex==EV[r_edge][1] ? 1 : -1
				cycle = cycle + rsign * r_coboundary
			end
			chain = setdiff(chain, findnz(cycle)[1])
		end
		for e in findnz(cscFE[f,:])[1]
			cscFE[f,e] = cycle[e]
		end
	end
	if exterior && size(V,1)==2
		# put matrix in form: first row outer cell; with opposite sign )
		V = convert(Array{Float64,2},transpose(V))
		EV = convert(Lar.ChainOp, SparseArrays.transpose(Lar.boundary_1(EV)))

		outer = Lar.Arrangement.get_external_cycle(V::Lar.Points, cscEV::Lar.ChainOp,
			cscFE::Lar.ChainOp)
		copFE = [ -cscFE[outer:outer,:];  cscFE[1:outer-1,:];  cscFE[outer+1:end,:] ]
		# induce coherent orientation of matrix rows (see examples/orient2d.jl)
		for k=1:size(copFE,2)
			spcolumn = findnz(copFE[:,k])
			if sum(spcolumn[2]) != 0
				row = spcolumn[1][2]
				sign = spcolumn[2][2]
				copFE[row,:] = -sign * copFE[row,:]
			end
		end
		return copFE
	else
		return cscFE
	end
end





"""
	u_boundary_2(FV::Lar.Cells, EV::Lar.Cells)::Lar.ChainOp

Return the unsigned `boundary_2` operator `C_2` -> `C_1`.
"""
u_boundary_2(EV, FV) = (Lar.u_coboundary_1(FV, EV))'



"""
	u_boundary_3(CV::Lar.Cells, FV::Lar.Cells)::Lar.ChainOp

Return the unsigned `boundary_2` operator `C_2` -> `C_1`.
"""
u_boundary_3(CV, FV) = (Lar.u_coboundary_1(CV, FV))'




"""
	u_coboundary_2( CV::Lar.Cells, FV::Lar.Cells[, convex=true::Bool] )::Lar.ChainOp

Unsigned 2-coboundary matrix `∂_2 : C_2 -> C_3` from 2-chain to 3-chain space.
Compute algebraically the *unsigned* coboundary matrix `∂_2` from
characteristic matrices of `CV` and `FV`. Currently usable *only* with complexes of *convex* cells.

#	Examples

## First example

(1) Compute the *boundary matrix* for a block of 3-cells of size ``[32,32,16]``;

(2) compute and show the *boundary* 2-cell array `boundary_2D_cells` by decodifying the (`mod 2`) result of multiplication of  the *boundary_3 matrix* `∂_2'`, transpose of *unsigned  coboundary_2* matrix  times the coordinate vector of the ``total`` 3-chain.

```julia
julia> using SparseArrays, Plasm
julia> V,(_,_,FV,CV) = Lar.cuboidGrid([32,32,16], true)
julia> ∂_2 = Lar.u_coboundary_2( CV, FV)
julia> coord_vect_of_all_3D_cells  = ones(size(∂_2,1),1)
julia> coord_vect_of_boundary_2D_cells = ∂_2' * coord_vect_of_all_3D_cells .% 2
julia> out = coord_vect_of_boundary_2D_cells
julia> boundary_2D_cells = [ FV[f] for f in findnz(sparse(out))[1] ]
julia> hpc = Plasm.lar2exploded_hpc(V, boundary_2D_cells)(1.,1.,1.)
julia> Plasm.view(hpc)
```
## Second example example

Using the boundary matrix of the `32 x 32 x 16` "image block" (better if stored on disk)
compute the boundary 2-complex of a random sub-image inside the block.

```julia
julia> coord_vect_of_segment = [x>0.25 ? 1 : 0  for x in rand(size(∂_2,1)) ]
julia> out = ∂_2' * coord_vect_of_segment .% 2
julia> boundary_2D_cells = [ FV[f] for f in findnz(sparse(out))[1] ]
julia> hpc = Plasm.lar2exploded_hpc(V, boundary_2D_cells)(1.1,1.1,1.1)
julia> Plasm.view(hpc)
```

"""
function u_coboundary_2( CV::Lar.Cells, FV::Lar.Cells, convex=true::Bool)::Lar.ChainOp
	cscCV = Lar.characteristicMatrix(CV)
	cscFV = Lar.characteristicMatrix(FV)
	temp = cscCV * cscFV'
	I,J,value = Int64[],Int64[],Int8[]
	for j=1:size(temp,2)
		nverts = length(FV[j])
		for i=1:size(temp,1)
			if temp[i,j] == nverts
				push!(I,i)
				push!(J,j)
				push!(value,1)
			end
		end
	end
	cscCF = SparseArrays.sparse(I,J,value)
	if !convex
		@assert "not yet implemented: TODO!"
	end
	return cscCF
end




"""
	chaincomplex( W::Points, EW::Cells )::Tuple{Array{Cells,1},Array{ChainOp,1}}

Chain 2-complex construction from basis of 1-cells.

From the minimal input, construct the whole
two-dimensional chain complex, i.e. the bases for linear spaces C_1 and
C_2 of 1-chains and  2-chains, and the signed coboundary operators from
C_0 to C_1 and from C_1 to C_2.

# Example

```julia
julia> W =
[0.0  0.0  0.0  0.0  1.0  1.0  1.0  1.0  2.0  2.0  2.0  2.0  3.0  3.0  3.0  3.0
0.0  1.0  2.0  3.0  0.0  1.0  2.0  3.0  0.0  1.0  2.0  3.0  0.0  1.0  2.0  3.0]
# output
2×16 Array{Float64,2}: ...

julia> EW =
[[1, 2],[2, 3],[3, 4],[5, 6],[6, 7],[7, 8],[9, 10],[10, 11],[11, 12],[13, 14],
[14, 15],[15, 16],[1, 5],[2, 6],[3, 7],[4, 8],[5, 9],[6, 10],[7, 11],[8, 12],
[9, 13],[10, 14],[11, 15],[12, 16]]
# output
24-element Array{Array{Int64,1},1}: ...

julia> V,bases,coboundaries = chaincomplex(W,EW)

julia> bases[1]	# edges
24-element Array{Array{Int64,1},1}: ...

julia> bases[2] # faces -- previously unknown !!
9-element Array{Array{Int64,1},1}: ...

julia> coboundaries[1] # coboundary_1
24×16 SparseMatrixCSC{Int8,Int64} with 48 stored entries: ...

julia> Matrix(coboundaries[2]) # coboundary_1: faces as oriented 1-cycles of edges
9×24 Array{Int8,2}:
-1  0  0  1  0  0  0  0  0  0  0  0  1 -1  0  0  0  0  0  0  0  0  0  0
0 -1  0  0  1  0  0  0  0  0  0  0  0  1 -1  0  0  0  0  0  0  0  0  0
0  0 -1  0  0  1  0  0  0  0  0  0  0  0  1 -1  0  0  0  0  0  0  0  0
0  0  0 -1  0  0  1  0  0  0  0  0  0  0  0  0  1 -1  0  0  0  0  0  0
0  0  0  0 -1  0  0  1  0  0  0  0  0  0  0  0  0  1 -1  0  0  0  0  0
0  0  0  0  0 -1  0  0  1  0  0  0  0  0  0  0  0  0  1 -1  0  0  0  0
0  0  0  0  0  0  0 -1  0  0  1  0  0  0  0  0  0  0  0  0  0  1 -1  0
0  0  0  0  0  0 -1  0  0  1  0  0  0  0  0  0  0  0  0  0  1 -1  0  0
0  0  0  0  0  0  0  0 -1  0  0  1  0  0  0  0  0  0  0  0  0  0  1 -1
```
"""
function chaincomplex( W, EW )
	V = convert(Array{Float64,2},LinearAlgebra.transpose(W))
	EV = convert(ChainOp, SparseArrays.transpose(boundary_1(EW)))

	V,cscEV,cscFE = Lar.planar_arrangement(V,EV)

	ne,nv = size(cscEV)
	nf = size(cscFE,1)
	EV = [findall(!iszero, cscEV[e,:]) for e=1:ne]
	FV = [collect(Set(vcat([EV[e] for e in findall(!iszero, cscFE[f,:])]...)))  for f=1:nf]

	function ord(cells)
		return [sort(cell) for cell in cells]
	end
	temp = copy(convert(ChainOp, LinearAlgebra.transpose(cscEV)))
	for k=1:size(temp,2)
		h = findall(!iszero, temp[:,k])[1]
		temp[h,k] = -1
	end
	cscEV = convert(ChainOp, LinearAlgebra.transpose(temp))
	bases, coboundaries = (ord(EV),ord(FV)), (cscEV,cscFE)
	return V',bases,coboundaries
end

"""
	chaincomplex( W::Points, FW::Cells, EW::Cells )
		::Tuple{ Array{Cells,1}, Array{ChainOp,1} }

Chain 3-complex construction from bases of 2- and 1-cells.

From the minimal input, construct the whole
two-dimensional chain complex, i.e. the bases for linear spaces C_1 and
C_2 of 1-chains and  2-chains, and the signed coboundary operators from
C_0 to C_1  and from C_1 to C_2.

# Example
```julia
julia> cube_1 = ([0 0 0 0 1 1 1 1; 0 0 1 1 0 0 1 1; 0 1 0 1 0 1 0 1],
[[1,2,3,4],[5,6,7,8],[1,2,5,6],[3,4,7,8],[1,3,5,7],[2,4,6,8]],
[[1,2],[3,4],[5,6],[7,8],[1,3],[2,4],[5,7],[6,8],[1,5],[2,6],[3,7],[4,8]] )

julia> cube_2 = Lar.Struct([Lar.t(0,0,0.5), Lar.r(0,0,pi/3), cube_1])

julia> V,FV,EV = Lar.struct2lar(Lar.Struct([ cube_1, cube_2 ]))

julia> V,bases,coboundaries = Lar.chaincomplex(V,FV,EV)

julia> (EV, FV, CV), (cscEV, cscFE, cscCF) = bases,coboundaries

julia> FV # bases[2]
18-element Array{Array{Int64,1},1}:
[1, 3, 4, 6]
[2, 3, 5, 6]
[7, 8, 9, 10]
[1, 2, 3, 7, 8]
[4, 6, 9, 10, 11, 12]
[5, 6, 11, 12]
[1, 4, 7, 9]
[2, 5, 11, 13]
[2, 8, 10, 11, 13]
[2, 3, 14, 15, 16]
[11, 12, 13, 17]
[11, 12, 13, 18, 19, 20]
[2, 3, 13, 17]
[2, 13, 14, 18]
[15, 16, 19, 20]
[3, 6, 12, 15, 19]
[3, 6, 12, 17]
[14, 16, 18, 20]

julia> CV # bases[3]
3-element Array{Array{Int64,1},1}:
[2, 3, 5, 6, 11, 12, 13, 14, 15, 16, 18, 19, 20]
[2, 3, 5, 6, 11, 12, 13, 17]
[1, 2, 3, 4, 6, 7, 8, 9, 10, 11, 12, 13, 17]

julia> cscEV # coboundaries[1]
34×20 SparseMatrixCSC{Int8,Int64} with 68 stored entries: ...

julia> cscFE # coboundaries[2]
18×34 SparseMatrixCSC{Int8,Int64} with 80 stored entries: ...

julia> cscCF # coboundaries[3]
4×18 SparseMatrixCSC{Int8,Int64} with 36 stored entries: ...
```
"""
function chaincomplex(V,FV,EV)
	W = convert(Lar.Points, copy(V)');
    cop_EV = Lar.coboundary_0(EV::Lar.Cells);
    cop_FE = Lar.coboundary_1(V, FV::Lar.Cells, EV::Lar.Cells);

    W, copEV, copFE, copCF = Lar.Arrangement.spatial_arrangement( W::Lar.Points, cop_EV::Lar.ChainOp, cop_FE::Lar.ChainOp)
@show "ECCOMI"
	ne,nv = size(copEV)
	nf = size(copFE,1)
	nc = size(copCF,1)
	EV = [findall(!iszero, copEV[e,:]) for e=1:ne]
	FV = [collect(Set(vcat([EV[e] for e in findall(!iszero, copFE[f,:])]...)))  for f=1:nf]
	CV = [collect(Set(vcat([FV[f] for f in findall(!iszero, copCF[c,:])]...)))  for c=2:nc]
	function ord(cells)
		return [sort(cell) for cell in cells]
	end
	temp = copy(convert(ChainOp, LinearAlgebra.transpose(copEV)))
	for k=1:size(temp,2)
		h = findall(!iszero, temp[:,k])[1]
		temp[h,k] = -1
	end
	copEV = convert(ChainOp, LinearAlgebra.transpose(temp))
	bases, coboundaries = (ord(EV),ord(FV),ord(CV)), (copEV,copFE,copCF)
	W = convert(Points, (LinearAlgebra.transpose(V')))
	return W,bases,coboundaries
end


# Collect LAR models in a single LAR model
function collection2model(collection)
	W,FW,EW = collection[1]
	shiftV = size(W,2)
	for k=2:length(collection)
		V,FV,EV = collection[k]
		W = [W V]
		FW = [FW; FV + shiftV]
		EW = [EW; EV + shiftV]
		shiftV = size(W,2)
	end
	return W,FW,EW
end



# 	"""
# 		facetriangulation(V::Points, FV::Cells, EV::Cells, cscFE::ChainOp, cscCF::ChainOp)

# 	Triangulation of a single facet of a 3-complex.

# 	# Example
# 	```julia
# 	julia> cube_1 = ([0 0 0 0 1 1 1 1; 0 0 1 1 0 0 1 1; 0 1 0 1 0 1 0 1],
# 	[[1,2,3,4],[5,6,7,8],[1,2,5,6],[3,4,7,8],[1,3,5,7],[2,4,6,8]],
# 	[[1,2],[3,4],[5,6],[7,8],[1,3],[2,4],[5,7],[6,8],[1,5],[2,6],[3,7],[4,8]] )

# 	julia> cube_2 = Lar.Struct([Lar.t(0,0,0.5), Lar.r(0,0,pi/3), cube_1])

# 	julia> W,FW,EW = Lar.struct2lar(Lar.Struct([ cube_1, cube_2 ]))

# 	julia> V,(EV,FV,EV),(cscEV,cscFE,cscCF) = Lar.chaincomplex(W,FW,EW)
# 	```
# 	"""
#    function facetriangulation(V,FV,EV,cscFE,cscCF)
#       function facetrias(f)
#          vs = [V[:,v] for v in FV[f]]
#          vs_indices = [v for v in FV[f]]
#          vdict = Dict([(i,index) for (i,index) in enumerate(vs_indices)])
#          dictv = Dict([(index,i) for (i,index) in enumerate(vs_indices)])
#          es = findall(!iszero, cscFE[f,:])

#          vts = [v-vs[1] for v in vs]

#          v1 = vts[2]
#          v2 = vts[3]
#          v3 = cross(v1,v2)
#          err, i = 1e-8, 1
#          while norm(v3) < err
#             v2 = vts[3+i]
#             i += 1
#             v3 = cross(v1,v2)
#          end

#          M = [v1 v2 v3]

#          vs_2D = hcat([(inv(M)*v)[1:2] for v in vts]...)'
#          pointdict = Dict([(vs_2D[k,:],k) for k=1:size(vs_2D,1)])
#          edges = hcat([[dictv[v] for v in EV[e]]  for e in es]...)'

#          trias = Triangle.constrained_triangulation_vertices(
#             vs_2D, collect(1:length(vs)), edges)

#          triangles = [[pointdict[t[1,:]],pointdict[t[2,:]],pointdict[t[3,:]]]
#             for t in trias]
#          mktriangles = [[vdict[t[1]],vdict[t[2]],vdict[t[3]]] for t in triangles]
#          return mktriangles
#       end
#       return facetrias
#    end

#    # Triangulation of the 2-skeleton
# 	"""

# 	"""
#    function triangulate(cf,V,FV,EV,cscFE,cscCF)
#       mktriangles = facetriangulation(V,FV,EV,cscFE,cscCF)
#       TV = Array{Int64,1}[]
#       for (f,sign) in zip(cf[1],cf[2])
#          triangles = mktriangles(f)
#          if sign == 1
#             append!(TV,triangles )
#          elseif sign == -1
#             append!(TV,[[t[2],t[1],t[3]] for t in triangles] )
#          end
#       end
#       return TV
#    end

#    # Map 3-cells to local bases
# 	"""

# 	"""
#    function map_3cells_to_localbases(V,CV,FV,EV,cscCF,cscFE)
#       local3cells = []
#       for c=1:length(CV)
#          cf = findnz(cscCF[c+1,:])
#          tv = triangulate(cf,V,FV,EV,cscFE,cscCF)
#          vs = sort(collect(Set(hcat(tv...))))
#          vsdict = Dict([(v,k) for (k,v) in enumerate(vs)])
#          tvs = [[vsdict[t[1]],vsdict[t[2]],vsdict[t[3]]] for t in tv]
#          v = hcat([V[:,w] for w in vs]...)
#          cell = [v,tvs]
#          append!(local3cells,[cell])
#       end
#       return local3cells
#    end
