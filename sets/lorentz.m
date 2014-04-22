function cvx_optpnt = lorentz( varargin )

%LORENTZ   Real second-order cone.
%   LORENTZ(N), where N is a positive integer, creates a column
%   variable of length N and a scalar variable, and constrains them
%   to lie in a second-order cone. That is, given the declaration
%       variables x(n) y
%   the constraint
%       {x,y} == lorentz(n)
%   is equivalent to
%       norm(x,2) <= y
%   The inequality form is more natural, and preferred in most cases. But
%   in fact, the LORENTZ set form is used by CVX itself to convert NORM()-
%   based constraints to solvable form.
%
%   LORENTZ(SX,DIM), where SX is a valid size vector and DIM is a positive
%   integer, creates an array variable of size SX and an array
%   variable of size SY (see below) and applies the second-order cone
%   constraint along dimension DIM. That is, given the declarations
%       sy = sx; sy(min(dim,length(sx)+1))=1;
%       variables x(sx) y(sy)
%   the constraint
%       {x,y} == lorentz(sx,dim)
%   is equivalent to
%       norms(x,2,dim) <= y
%   Again, the inequality form is preferred, but CVX uses the set form
%   internally. DIM is optional; if it is omitted, the first non-singleton
%   dimension is used.
%
%   LORENTZ(SX,DIM,CPLX) creates real second-order cones if CPLX is FALSE,
%   and complex second-order cones if CPLX is TRUE. The latter case is
%   equivalent to COMPLEX_LORENTZ(SX,DIM).
%
%   Disciplined convex programming information:
%       LORENTZ is a cvx set specification. See the user guide for
%       details on how to use sets.

global cvx___

%
% Get size and dimension
%

[ sx, dim, iscplx ] = cvx_get_dimension( varargin, 2, 'nox', true, 'zero', true ); %#ok
sy = sx;
nd = length( sx );
nv = sx( dim );
sy( dim ) = 1;

%
% Check complex flag
%

if isempty( iscplx ),
    iscplx = false;
elseif length( iscplx ) ~= 1,
    error( 'Third argument must be a scalar.' );
else
    iscplx = logical( iscplx );
end

%
% Build the cone
%

ny = prod( sy );
if nv == 0,
    iscplx = false;
elseif iscplx,
    nv = nv * 2;
end
cvx_begin set
    variables x( nv, ny ) y( 1, ny )
    [ ty, dummy ] = find( cvx_basis( y ) ); %#ok
    if nv > 0,
        [ tx, dummy ] = find( cvx_basis( x ) ); %#ok
        newnonl( cvx_problem, 'lorentz', [ reshape( tx, nv, ny ) ; reshape( ty, 1, ny ) ] );
        cvx___.canslack( tx ) = false;
    else
        newnonl( cvx_problem, 'nonnegative', ty );
    end
    cvx___.sign( ty ) = 1;
cvx_end

%
% Permute and reshape as needed
%

if iscplx,
    x = cvx_basis( x );
    x = x(:,1:2:end) + 1j * x(:,2:2:end);
    nv = nv * 0.5;
    x = cvx( [nv,ny], x );
end
if sx( dim ) > 1,
    nleft = prod( sx( 1 : dim - 1 ) );
    if nleft > 1,
        x = reshape( x, [ nv, nleft, ny / nleft ] );
        y = reshape( y, [ 1,  nleft, ny / nleft ] );
        x = permute( x, [ 2, 1, 3 ] );
        y = permute( y, [ 2, 1, 3 ] );
    end
end
x = reshape( x, sx );
y = reshape( y, sy );
cvx_optpnt = cvxtuple( struct( 'x', x, 'y', y ) );

% Copyright 2005-2014 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
