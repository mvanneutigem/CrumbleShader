float4x4 gWorld : WORLD;
float4x4 gView : VIEW;
float4x4 gWorldViewProj : WORLDVIEWPROJECTION; 
//float m_Timer : TIME;
float m_Timer<
		string UIName = "time";
		string UIWidget = "Slider";
		float UIMin = 0.0f;
		float UIMax = 20.0f;
		float UIStep = 0.1f;
	> = 1.0f;

float3 gLightDirection = float3(-0.577f, -0.577f, 0.577f);
float m_FallSeedY<
		string UIName = "fall seed Y";
		string UIWidget = "Slider";
		float UIMin = 0.0f;
		float UIMax = 100.0f;
		float UIStep = 1.0f;
	> = 9.81;
float m_FallMultiply<
	string UIName = "Fall multiplier";
	string UIWidget = "Slider";
	float UIMin = 0.0f;
	float UIMax = 100.0f;
	float UIStep = 1.0f;
> = 9.81;
float m_Thickness<
	string UIName = "shell thickness";
	string UIWidget = "Slider";
	float UIMin = 0.0f;
	float UIMax = 10.0f;
	float UIStep = 0.1f;
> = 0.1f;
float m_VoxelGridSize<
		string UIName = "voxel grid size";
		string UIWidget = "Slider";
		float UIMin = 0.0f;
		float UIMax = 10.0f;
		float UIStep = 0.01f;
	> = 1.0f;
float m_VoxelBlockSize<
	string UIName = "voxel block size";
	string UIWidget = "Slider";
	float UIMin = 0.0f;
	float UIMax = 100.0f;
	float UIStep = 0.01f;
> = 0.1f;
Texture2D gDiffuseMap
<
	string UIName = "Diffuse Texture";
	string UIWidget = "Texture";
	string ResourceName = "wall_texture.jpg";//"platform_1_tex.jpg";
>;
float m_FallSeedX<
	string UIName = "fall seed x";
	string UIWidget = "Slider";
	float UIMin = 0.0f;
	float UIMax = 100.0f;
	float UIStep = 1.0f;
> = 0.1f;

//--------------------------------------------------------------------------------------
// States
//--------------------------------------------------------------------------------------
DepthStencilState EnableDepth
{ 
	DepthEnable = TRUE;
	DepthWriteMask = ALL;
};

RasterizerState NoCulling
{
	FillMode = SOLID;//SOLID;
	CullMode = NONE;//NONE
};

SamplerState samLinear
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Wrap;
    AddressV = Wrap;
};

//--------------------------------------------------------------------------------------
// Structs
//--------------------------------------------------------------------------------------
struct VS_DATA
{
	float3 Position : POSITION;
	float3 Normal : NORMAL;
    float2 TexCoord : TEXCOORD;
};

struct GS_DATA
{
	float4 Position : SV_POSITION;
	float3 Normal : NORMAL;
	float2 TexCoord : TEXCOORD0;
};

//--------------------------------------------------------------------------------------
// Vertex Shader
//--------------------------------------------------------------------------------------
//float array[200];
VS_DATA VS(VS_DATA vsData)
{
	//array[0] = 5.0f;
	return vsData;
}

//--------------------------------------------------------------------------------------
// Geometry shader
//--------------------------------------------------------------------------------------

float4 PosToWorldSpace(float4 pos)
{
	return mul(pos,gWorldViewProj);
}

float3 NormalToWorldSpace(float3 normal)
{
	return mul(normal, (float3x3)gWorld);
}

void SplitFragmentInTwo(triangle VS_DATA vertices[3], float3 explodedPosition[3], GS_DATA outVertices[16], inout TriangleStream<GS_DATA> triStream, bool reverseWinding = true)
{
	//vert 1 and vert 2 together, vert 3 separate
	float3 v1t3 = vertices[2].Position - vertices[0].Position;
	float3 v2t3 = vertices[2].Position - vertices[1].Position;
	float3 v1t2 = vertices[1].Position - vertices[0].Position;
	
	//interpolate texcoord
	float2 texCoord1 = vertices[2].TexCoord + vertices[0].TexCoord;
	texCoord1 *= 0.5f;
	float2 texCoord2 = vertices[2].TexCoord + vertices[1].TexCoord;
	texCoord2 *= 0.5f;
	float2 texCoord3 = vertices[0].TexCoord + vertices[1].TexCoord;
	texCoord3 *= 0.5f;
	
	//interpolate normals
	float3 normal1 = vertices[2].Normal + vertices[0].Normal;
	normalize(normal1);
	float3 normal2 = vertices[2].Normal + vertices[1].Normal;
	normalize(normal2);
	float3 normal3 = vertices[0].Normal + vertices[1].Normal;
	normalize(normal3);
	
	//split fragments
	v1t3 *= 0.5f;
	v2t3 *= 0.5f;
	v1t2 *= 0.5f;
	float3 v3t1 = -v1t3 + explodedPosition[2];
	float3 v3t2 = -v2t3 + explodedPosition[2];
	v1t3 += explodedPosition[0];
	v2t3 += explodedPosition[1];
	v1t2 += (explodedPosition[0]);
	
	//shell
	GS_DATA tempvert[16] = (GS_DATA[16])0;
	
	if (reverseWinding)
	{
		//fragment v1v2
		outVertices[1].Position = mul(float4(explodedPosition[1],1),gWorldViewProj);
		outVertices[1].Normal = mul(vertices[1].Normal, (float3x3)gWorld);
		outVertices[1].TexCoord = vertices[1].TexCoord;
		triStream.Append(outVertices[1]);
					
		outVertices[3].Position = mul(float4(v2t3,1),gWorldViewProj);
		outVertices[3].Normal = mul(normal2, (float3x3)gWorld);
		outVertices[3].TexCoord = texCoord2;
		triStream.Append(outVertices[3]);
		
		outVertices[2].Position = mul(float4(v1t2,1),gWorldViewProj);
		outVertices[2].Normal = mul(normal3, (float3x3)gWorld);
		outVertices[2].TexCoord = texCoord3;
		triStream.Append(outVertices[2]);
		
		outVertices[4].Position = mul(float4(v1t3,1),gWorldViewProj);
		outVertices[4].Normal = mul(normal1, (float3x3)gWorld);
		outVertices[4].TexCoord = texCoord1;
		triStream.Append(outVertices[4]);
		
		outVertices[0].Position = mul(float4(explodedPosition[0],1),gWorldViewProj);
		outVertices[0].Normal = mul(vertices[0].Normal, (float3x3)gWorld);
		outVertices[0].TexCoord = vertices[0].TexCoord;
		triStream.Append(outVertices[0]);
		
		triStream.RestartStrip();
		
		//shell
		//----
		tempvert[0].Position = float4(explodedPosition[1], 1) - m_Thickness* float4(normalize(outVertices[1].Normal), 0);
		tempvert[0].Position = mul(tempvert[0].Position, gWorldViewProj);
		tempvert[0].Normal = mul(-vertices[1].Normal, (float3x3)gWorld);
		tempvert[0].TexCoord = outVertices[1].TexCoord;
		triStream.Append(tempvert[0]);
		
		tempvert[1].Position = float4(v2t3,1) - m_Thickness* float4(normalize(outVertices[3].Normal), 0);
		tempvert[1].Position = mul(tempvert[1].Position, gWorldViewProj);
		tempvert[1].Normal = mul(-normal2, (float3x3)gWorld);
		tempvert[1].TexCoord = outVertices[3].TexCoord;
		triStream.Append(tempvert[1]);
		
		tempvert[2].Position = float4(v1t2,1) - m_Thickness* float4(normalize(outVertices[2].Normal), 0);
		tempvert[2].Position = mul(tempvert[2].Position, gWorldViewProj);
		tempvert[2].Normal = mul(-normal3, (float3x3)gWorld);
		tempvert[2].TexCoord = outVertices[2].TexCoord;
		triStream.Append(tempvert[2]);
		
		tempvert[3].Position = float4(v1t3,1) - m_Thickness* float4(normalize(outVertices[4].Normal), 0);
		tempvert[3].Position = mul(tempvert[3].Position, gWorldViewProj);
		tempvert[3].Normal = mul(-normal1, (float3x3)gWorld);
		tempvert[3].TexCoord = outVertices[4].TexCoord;
		triStream.Append(tempvert[3]);
		
		tempvert[4].Position = float4(explodedPosition[0], 1) - m_Thickness* float4(normalize(outVertices[0].Normal), 0);
		tempvert[4].Position = mul(tempvert[4].Position, gWorldViewProj);
		tempvert[4].Normal = mul(-vertices[0].Normal, (float3x3)gWorld);
		tempvert[4].TexCoord = outVertices[0].TexCoord;
		triStream.Append(tempvert[4]);
		
		triStream.RestartStrip();
		
		//v1v2 cap
		float3 surfNormal = normalize(cross( (tempvert[3].Position - outVertices[4].Position),(tempvert[3].Position - outVertices[3].Position) ) );
		
		tempvert[3].Normal = surfNormal;
		outVertices[4].Normal = surfNormal;
		tempvert[1].Normal = surfNormal;
		outVertices[3].Normal = surfNormal;
		
		outVertices[4].TexCoord = tempvert[3].TexCoord;
		tempvert[1].TexCoord = tempvert[3].TexCoord;
		outVertices[3].TexCoord = tempvert[3].TexCoord;
		
		triStream.Append(tempvert[3]);
		triStream.Append(outVertices[4]);
		triStream.Append(tempvert[1]);
		triStream.Append(outVertices[3]);
		triStream.RestartStrip();
		
		//fragment v3
		outVertices[4].Position = mul(float4(explodedPosition[2],1),gWorldViewProj);
		outVertices[4].Normal = mul(vertices[2].Normal, (float3x3)gWorld);
		outVertices[4].TexCoord = vertices[2].TexCoord;
		triStream.Append(outVertices[4]);
		
		outVertices[5].Position = mul(float4(v3t1,1),gWorldViewProj);
		outVertices[5].Normal = mul(normal1, (float3x3)gWorld);
		outVertices[5].TexCoord = texCoord1;
		triStream.Append(outVertices[5]);
		
		outVertices[6].Position = mul(float4(v3t2,1),gWorldViewProj);
		outVertices[6].Normal = mul(normal2, (float3x3)gWorld);
		outVertices[6].TexCoord = texCoord2;
		triStream.Append(outVertices[6]);
		
		triStream.RestartStrip();
	
		//shell
		//------
		
		tempvert[5].Position = float4(explodedPosition[2], 1) - m_Thickness* float4(normalize(outVertices[4].Normal), 0);
		tempvert[5].Position = mul(tempvert[5].Position, gWorldViewProj);
		tempvert[5].Normal = mul(-vertices[2].Normal, (float3x3)gWorld);
		tempvert[5].TexCoord = outVertices[4].TexCoord;
		triStream.Append(tempvert[5]);
		
		tempvert[6].Position = float4(v3t1,1) - m_Thickness* float4(normalize(outVertices[5].Normal), 0);
		tempvert[6].Position = mul(tempvert[6].Position, gWorldViewProj);
		tempvert[6].Normal = mul(-normal1, (float3x3)gWorld);
		tempvert[6].TexCoord = outVertices[5].TexCoord;
		triStream.Append(tempvert[6]);
		
		tempvert[7].Position = float4(v3t2,1) - m_Thickness* float4(normalize(outVertices[6].Normal), 0);
		tempvert[7].Position = mul(tempvert[7].Position, gWorldViewProj);
		tempvert[7].Normal = mul(-normal2, (float3x3)gWorld);
		tempvert[7].TexCoord = outVertices[6].TexCoord;
		triStream.Append(tempvert[7]);
		
		triStream.RestartStrip();
		
		//v3 cap
		surfNormal = normalize(cross( (tempvert[6].Position - outVertices[5].Position),(tempvert[6].Position - outVertices[6].Position) ) );
		
		tempvert[6].Normal = surfNormal;
		outVertices[5].Normal = surfNormal;
		tempvert[7].Normal = surfNormal;
		outVertices[6].Normal = surfNormal;
		
		outVertices[5].TexCoord = tempvert[6].TexCoord;
		tempvert[7].TexCoord = tempvert[6].TexCoord;
		outVertices[6].TexCoord = tempvert[6].TexCoord;
		
		triStream.Append(tempvert[6]);//average the texcoords here
		triStream.Append(outVertices[5]);
		triStream.Append(tempvert[7]);
		triStream.Append(outVertices[6]);
		triStream.RestartStrip();
	}
	else
	{
		//fragment v1v2
		outVertices[0].Position = mul(float4(explodedPosition[0],1),gWorldViewProj);
		outVertices[0].Normal = mul(vertices[0].Normal, (float3x3)gWorld);
		outVertices[0].TexCoord = vertices[0].TexCoord;
		triStream.Append(outVertices[0]);
		
		outVertices[2].Position = mul(float4(v1t3,1),gWorldViewProj);
		outVertices[2].Normal = mul(normal1, (float3x3)gWorld);
		outVertices[2].TexCoord = texCoord1;//still need to interpolate texcoord && normals
		triStream.Append(outVertices[2]);
		
		outVertices[4].Position = mul(float4(v1t2,1),gWorldViewProj);
		outVertices[4].Normal = mul(normal3, (float3x3)gWorld);
		outVertices[4].TexCoord = texCoord3;//still need to interpolate texcoord && normals
		triStream.Append(outVertices[4]);
		
		outVertices[3].Position = mul(float4(v2t3,1),gWorldViewProj);
		outVertices[3].Normal = mul(normal2, (float3x3)gWorld);
		outVertices[3].TexCoord = texCoord2;
		triStream.Append(outVertices[3]);
		
		outVertices[1].Position = mul(float4(explodedPosition[1],1),gWorldViewProj);
		outVertices[1].Normal = mul(vertices[1].Normal, (float3x3)gWorld);
		outVertices[1].TexCoord = vertices[1].TexCoord;
		triStream.Append(outVertices[1]);
					
		triStream.RestartStrip();
		
		//shell
		//----
		tempvert[0].Position = float4(explodedPosition[0], 1) - m_Thickness* float4(normalize(outVertices[0].Normal), 0);
		tempvert[0].Position = mul(tempvert[0].Position, gWorldViewProj);
		tempvert[0].Normal = mul(-vertices[0].Normal, (float3x3)gWorld);
		tempvert[0].TexCoord = outVertices[0].TexCoord;
		triStream.Append(tempvert[0]);
		
		tempvert[1].Position = float4(v1t3,1) - m_Thickness* float4(normalize(outVertices[2].Normal), 0);
		tempvert[1].Position = mul(tempvert[1].Position, gWorldViewProj);
		tempvert[1].Normal = mul(-normal2, (float3x3)gWorld);
		tempvert[1].TexCoord = outVertices[2].TexCoord;
		triStream.Append(tempvert[1]);
		
		tempvert[2].Position = float4(v1t2,1) - m_Thickness* float4(normalize(outVertices[4].Normal), 0);
		tempvert[2].Position = mul(tempvert[2].Position, gWorldViewProj);
		tempvert[2].Normal = mul(-normal3, (float3x3)gWorld);
		tempvert[2].TexCoord = outVertices[4].TexCoord;
		triStream.Append(tempvert[2]);
		
		tempvert[3].Position = float4(v2t3,1) - m_Thickness* float4(normalize(outVertices[3].Normal), 0);
		tempvert[3].Position = mul(tempvert[3].Position, gWorldViewProj);
		tempvert[3].Normal = mul(-normal2, (float3x3)gWorld);
		tempvert[3].TexCoord = outVertices[3].TexCoord;
		triStream.Append(tempvert[3]);
		
		tempvert[4].Position = float4(explodedPosition[1], 1) - m_Thickness* float4(normalize(outVertices[1].Normal), 0);
		tempvert[4].Position = mul(tempvert[4].Position, gWorldViewProj);
		tempvert[4].Normal = mul(-vertices[1].Normal, (float3x3)gWorld);
		tempvert[4].TexCoord = outVertices[1].TexCoord;
		triStream.Append(tempvert[4]);
		
		triStream.RestartStrip();
		
		//v1v2 cap
		float3 surfNormal = normalize(cross( (tempvert[1].Position - outVertices[2].Position),(tempvert[1].Position - outVertices[3].Position) ) );
		
		tempvert[1].Normal = surfNormal;
		outVertices[2].Normal = surfNormal;
		tempvert[3].Normal = surfNormal;
		outVertices[3].Normal = surfNormal;
		
		outVertices[2].TexCoord = tempvert[1].TexCoord;
		tempvert[3].TexCoord = tempvert[1].TexCoord;
		outVertices[3].TexCoord = tempvert[1].TexCoord;
		
		triStream.Append(tempvert[1]);
		triStream.Append(outVertices[2]);
		triStream.Append(tempvert[3]);
		triStream.Append(outVertices[3]);
		triStream.RestartStrip();
		
		//fragment v3
		outVertices[6].Position = mul(float4(v3t2,1),gWorldViewProj);
		outVertices[6].Normal = mul(normal2, (float3x3)gWorld);
		outVertices[6].TexCoord = texCoord2;
		triStream.Append(outVertices[6]);
		
		outVertices[5].Position = mul(float4(v3t1,1),gWorldViewProj);
		outVertices[5].Normal = mul(normal1, (float3x3)gWorld);
		outVertices[5].TexCoord = texCoord1;
		triStream.Append(outVertices[5]);
		
		outVertices[4].Position = mul(float4(explodedPosition[2],1),gWorldViewProj);
		outVertices[4].Normal = mul(vertices[2].Normal, (float3x3)gWorld);
		outVertices[4].TexCoord = vertices[2].TexCoord;
		triStream.Append(outVertices[4]);
		
		triStream.RestartStrip();
		
		//shell
		//------
		tempvert[5].Position = float4(v3t2,1) - m_Thickness* float4(normalize(outVertices[6].Normal), 0);
		tempvert[5].Position = mul(tempvert[5].Position, gWorldViewProj);
		tempvert[5].Normal = mul(-normal2, (float3x3)gWorld);
		tempvert[5].TexCoord = outVertices[6].TexCoord;
		triStream.Append(tempvert[5]);
		
		tempvert[6].Position = float4(v3t1,1) - m_Thickness* float4(normalize(outVertices[5].Normal), 0);
		tempvert[6].Position = mul(tempvert[6].Position, gWorldViewProj);
		tempvert[6].Normal = mul(-normal1, (float3x3)gWorld);
		tempvert[6].TexCoord = outVertices[5].TexCoord;
		triStream.Append(tempvert[6]);
		
		tempvert[7].Position = float4(explodedPosition[2], 1) - m_Thickness* float4(normalize(outVertices[4].Normal), 0);
		tempvert[7].Position = mul(tempvert[7].Position, gWorldViewProj);
		tempvert[7].Normal = mul(-vertices[2].Normal, (float3x3)gWorld);
		tempvert[7].TexCoord = outVertices[4].TexCoord;
		triStream.Append(tempvert[7]);
		triStream.RestartStrip();
		
		//v3 cap
		//calc surface normal
		surfNormal = normalize(cross( (tempvert[5].Position - outVertices[6].Position),(tempvert[5].Position - outVertices[5].Position) ) );
		
		tempvert[5].Normal = surfNormal;
		outVertices[6].Normal = surfNormal;
		tempvert[6].Normal = surfNormal;
		outVertices[5].Normal = surfNormal;
		
		outVertices[6].TexCoord = tempvert[5].TexCoord;
		tempvert[6].TexCoord = tempvert[5].TexCoord;
		outVertices[5].TexCoord = tempvert[5].TexCoord;
		
		triStream.Append(tempvert[5]);
		triStream.Append(outVertices[6]);
		triStream.Append(tempvert[6]);
		triStream.Append(outVertices[5]);
		triStream.RestartStrip();
	}
	
}

bool Comparefloat3(float3 a, float3 b)
{
	if(a.x ==b.x && a.y == b.y && a.z == b.z)
	return true;
	else
	return false;
}

void CreateFragment(triangle VS_DATA vertices[3], inout TriangleStream<GS_DATA> triStream)
{
	GS_DATA outVertices[16] = (GS_DATA[16])0;
	
	//calculating indices
	int j1 = m_VoxelGridSize/2.0f + vertices[0].Position.x / m_VoxelBlockSize;
	int k1 = m_VoxelGridSize/2.0f + vertices[0].Position.y / m_VoxelBlockSize;
	int l1 = m_VoxelGridSize/2.0f + vertices[0].Position.z / m_VoxelBlockSize;
	
	int j2 = m_VoxelGridSize/2.0f + vertices[1].Position.x / m_VoxelBlockSize;
	int k2 = m_VoxelGridSize/2.0f + vertices[1].Position.y / m_VoxelBlockSize;
	int l2 = m_VoxelGridSize/2.0f + vertices[1].Position.z / m_VoxelBlockSize;
	
	int j3 = m_VoxelGridSize/2.0f + vertices[2].Position.x / m_VoxelBlockSize;
	int k3 = m_VoxelGridSize/2.0f + vertices[2].Position.y / m_VoxelBlockSize;
	int l3 = m_VoxelGridSize/2.0f + vertices[2].Position.z / m_VoxelBlockSize;
	
	
	float offset1 = (m_Timer * -0.01f*m_FallMultiply*abs( m_VoxelGridSize + (m_FallSeedY*(m_VoxelGridSize-k1)) + m_FallSeedX*(j1 - l1 * l1)));
	float offset2 = (m_Timer * -0.01f*m_FallMultiply*abs( m_VoxelGridSize + (m_FallSeedY*(m_VoxelGridSize-k2)) + m_FallSeedX*(j2 - l2 * l2)));
	float offset3 = (m_Timer * -0.01f*m_FallMultiply*abs( m_VoxelGridSize + (m_FallSeedY*(m_VoxelGridSize-k3)) + m_FallSeedX*(j3 - l3 * l3)));
	
	//making sure clusters stick together on movement
	float3 explodedPosition[3];
	explodedPosition[0].x = vertices[0].Position.x;
	explodedPosition[0].y = vertices[0].Position.y + offset1;
	explodedPosition[0].z = vertices[0].Position.z;
	explodedPosition[1].x = vertices[1].Position.x;
	explodedPosition[1].y = vertices[1].Position.y + offset2;
	explodedPosition[1].z = vertices[1].Position.z;
	explodedPosition[2].x = vertices[2].Position.x;
	explodedPosition[2].y = vertices[2].Position.y + offset3;
	explodedPosition[2].z = vertices[2].Position.z;
	
	//check if vertices in the same cluster
	if (j1 == j2 && k1 == k2 && l1 == l2)
	{
			
		if (j3 == j2 && k3 == k2 && l3 == l2)
		{
			//all in the same cluster:
			GS_DATA tempverts[3] = (GS_DATA[3])0;
			for(int i =0; i< 3 ; ++i)
			{
				outVertices[i].Position = mul(float4(explodedPosition[i],1),gWorldViewProj);
				outVertices[i].Normal = mul(vertices[i].Normal, (float3x3)gWorld);
				outVertices[i].TexCoord = vertices[i].TexCoord;
				
				//shell
				tempverts[i].Position = float4(explodedPosition[i],1) - m_Thickness* float4(normalize(outVertices[i].Normal), 0);
				tempverts[i].Position = mul(tempverts[i].Position, gWorldViewProj);
				tempverts[i].Normal = mul(-vertices[i].Normal, (float3x3)gWorld);
				tempverts[i].TexCoord = outVertices[i].TexCoord;
				
				triStream.Append(outVertices[i]);
			}
			triStream.RestartStrip();
			
			//shell
			for(int w =0; w <3 ; ++w)
			{
				triStream.Append(tempverts[w]);
			}
			triStream.RestartStrip();
		}
		else
		{
			SplitFragmentInTwo(vertices,explodedPosition, outVertices, triStream);
			
		}
	}
	else
	{
		if (j3 == j2 && k3 == k2 && l3 == l2)
		{
			//setting order of verts to make function work
			VS_DATA tempVertices[3];
			tempVertices[0] = vertices[2];
			tempVertices[1] = vertices[1];
			tempVertices[2] = vertices[0];
			
			float3 tempPositions[3];
			tempPositions[0] = explodedPosition[2];
			tempPositions[1] = explodedPosition[1];
			tempPositions[2] = explodedPosition[0];
			
			SplitFragmentInTwo(tempVertices,tempPositions, outVertices, triStream, false);
			
			
		}
		else if (j3 == j1 && k3 == k1 && l3 == l1)
		{
			//setting order of verts to make function work
			VS_DATA tempVertices[3];
			tempVertices[0] = vertices[0];
			tempVertices[1] = vertices[2];
			tempVertices[2] = vertices[1];
			
			float3 tempPositions[3];
			tempPositions[0] = explodedPosition[0];
			tempPositions[1] = explodedPosition[2];
			tempPositions[2] = explodedPosition[1];
			
			SplitFragmentInTwo(tempVertices,tempPositions, outVertices, triStream, false);
			
		}
		else
		{
			//temp for shell
			GS_DATA tempvert[4] = (GS_DATA[4])0;
			
			//all vertices separate
			float3 v1t3 = vertices[2].Position - vertices[0].Position;
			float3 v2t1 = vertices[0].Position - vertices[1].Position;
			float3 v3t2 = vertices[1].Position - vertices[2].Position;
			
			//interpolate texcoord
			float2 texCoord1 = vertices[1].TexCoord + vertices[0].TexCoord;
			texCoord1 *= 0.5f;
			float2 texCoord2 = vertices[1].TexCoord + vertices[2].TexCoord;
			texCoord2 *= 0.5f;
			float2 texCoord3 = vertices[0].TexCoord + vertices[2].TexCoord;
			texCoord3 *= 0.5f;
			
			//interpolate normals
			float3 normal1 = vertices[2].Normal + vertices[0].Normal;
			normalize(normal1);
			float3 normal2 = vertices[2].Normal + vertices[1].Normal;
			normalize(normal2);
			float3 normal3 = vertices[0].Normal + vertices[1].Normal;
			normalize(normal3);
			
			//split fragments
			v1t3 *= 0.5f;
			v2t1 *= 0.5f;
			v3t2 *= 0.5f;
			
			//middle frag
			float3 v4t1 = v1t3 - v2t1;
			float3 v4t2 = v2t1 - v3t2;
			float3 v4t3 = v3t2 - v1t3;
		
			//classify middle frag --> too big a calculation would cause so much lag so for now all on one set fragment
			
			int j = j2;
			int k = k2;
			int l = l2;
			
			float3 tempXplodePos[3];
			tempXplodePos[0].x = vertices[0].Position.x;
			tempXplodePos[0].y = vertices[0].Position.y + (m_Timer * -0.01f*m_FallMultiply* abs( m_VoxelGridSize + (m_FallSeedY*(m_VoxelGridSize-k)) + m_FallSeedX*(j - l * l)));
			tempXplodePos[0].z = vertices[0].Position.z;
			tempXplodePos[1].x = vertices[1].Position.x;
			tempXplodePos[1].y = vertices[1].Position.y + (m_Timer * -0.01f*m_FallMultiply* abs( m_VoxelGridSize + (m_FallSeedY*(m_VoxelGridSize-k)) + m_FallSeedX*(j - l * l)));
			tempXplodePos[1].z = vertices[1].Position.z;
			tempXplodePos[2].x = vertices[2].Position.x;
			tempXplodePos[2].y = vertices[2].Position.y + (m_Timer * -0.01f*m_FallMultiply* abs( m_VoxelGridSize + (m_FallSeedY*(m_VoxelGridSize-k)) + m_FallSeedX*(j - l * l)));
			tempXplodePos[2].z = vertices[2].Position.z;
			
			v4t1 += tempXplodePos[0];
			v4t2 += tempXplodePos[1];
			v4t3 += tempXplodePos[2];
			
			
			float3 v1t2 = -v2t1 + explodedPosition[0];
			float3 v2t3 = -v3t2 + explodedPosition[1];
			float3 v3t1 = -v1t3 + explodedPosition[2];
			v1t3 += explodedPosition[0];
			v2t1 += explodedPosition[1];
			v3t2 += explodedPosition[2];
			
			//fragment v1
			outVertices[4].Position = mul(float4(explodedPosition[0],1),gWorldViewProj);
			outVertices[4].Normal = mul(vertices[0].Normal, (float3x3)gWorld);
			outVertices[4].TexCoord = vertices[0].TexCoord;
			triStream.Append(outVertices[4]);
						
			outVertices[6].Position = mul(float4(v1t2,1),gWorldViewProj);
			outVertices[6].Normal = mul(normal3, (float3x3)gWorld);
			outVertices[6].TexCoord = texCoord1;
			triStream.Append(outVertices[6]);
			
			outVertices[5].Position = mul(float4(v1t3,1),gWorldViewProj);
			outVertices[5].Normal = mul(normal1, (float3x3)gWorld);
			outVertices[5].TexCoord = texCoord3;
			triStream.Append(outVertices[5]);
			triStream.RestartStrip();
			
			//shell v1
			tempvert[0].Position = float4(explodedPosition[0],1) - m_Thickness* float4(normalize(outVertices[4].Normal), 0);
			tempvert[0].Position = mul(tempvert[0].Position, gWorldViewProj);
			tempvert[0].Normal = mul(-vertices[0].Normal, (float3x3)gWorld);
			tempvert[0].TexCoord = outVertices[4].TexCoord;
			triStream.Append(tempvert[0]);
			
			tempvert[1].Position = float4(v1t2,1) - m_Thickness* float4(normalize(outVertices[6].Normal), 0);
			tempvert[1].Position = mul(tempvert[1].Position, gWorldViewProj);
			tempvert[1].Normal = mul(-normal3, (float3x3)gWorld);
			tempvert[1].TexCoord = outVertices[6].TexCoord;
			triStream.Append(tempvert[1]);
			
			tempvert[2].Position = float4(v1t3,1) - m_Thickness* float4(normalize(outVertices[5].Normal), 0);
			tempvert[2].Position = mul(tempvert[2].Position, gWorldViewProj);
			tempvert[2].Normal = mul(-normal1, (float3x3)gWorld);
			tempvert[2].TexCoord = outVertices[5].TexCoord;
			triStream.Append(tempvert[2]);
			
			triStream.RestartStrip();
			
			//v1 cap
			float3 surfNormal = normalize(cross( (tempvert[2].Position - outVertices[5].Position),(tempvert[2].Position - outVertices[6].Position) ) );
		
			tempvert[2].Normal = surfNormal;
			outVertices[5].Normal = surfNormal;
			tempvert[1].Normal = surfNormal;
			outVertices[6].Normal = surfNormal;
			
			outVertices[5].TexCoord = tempvert[2].TexCoord;
			tempvert[1].TexCoord = tempvert[2].TexCoord;
			outVertices[6].TexCoord = tempvert[2].TexCoord;
			
			triStream.Append(tempvert[2]);//average the texcoords here
			triStream.Append(outVertices[5]);
			triStream.Append(tempvert[1]);
			triStream.Append(outVertices[6]);
			triStream.RestartStrip();
			
			//fragment v2
			outVertices[4].Position = mul(float4(explodedPosition[1],1),gWorldViewProj);
			outVertices[4].Normal = mul(vertices[1].Normal, (float3x3)gWorld);
			outVertices[4].TexCoord = vertices[1].TexCoord;
			triStream.Append(outVertices[4]);
						
			outVertices[6].Position = mul(float4(v2t3,1),gWorldViewProj);
			outVertices[6].Normal = mul(normal2, (float3x3)gWorld);
			outVertices[6].TexCoord = texCoord2;
			triStream.Append(outVertices[6]);
			
			outVertices[5].Position = mul(float4(v2t1,1),gWorldViewProj);
			outVertices[5].Normal = mul(normal3, (float3x3)gWorld);
			outVertices[5].TexCoord = texCoord1;
			triStream.Append(outVertices[5]);
			triStream.RestartStrip();
			
			//shell v2
			tempvert[0].Position = float4(explodedPosition[1],1) - m_Thickness* float4(normalize(outVertices[4].Normal), 0);
			tempvert[0].Position = mul(tempvert[0].Position, gWorldViewProj);
			tempvert[0].Normal = mul(-vertices[0].Normal, (float3x3)gWorld);
			tempvert[0].TexCoord = outVertices[4].TexCoord;
			triStream.Append(tempvert[0]);
			
			tempvert[1].Position = float4(v2t3,1) - m_Thickness* float4(normalize(outVertices[6].Normal), 0);
			tempvert[1].Position = mul(tempvert[1].Position, gWorldViewProj);
			tempvert[1].Normal = mul(-normal1, (float3x3)gWorld);
			tempvert[1].TexCoord = outVertices[6].TexCoord;
			triStream.Append(tempvert[1]);
			
			tempvert[2].Position = float4(v2t1,1) - m_Thickness* float4(normalize(outVertices[5].Normal), 0);
			tempvert[2].Position = mul(tempvert[2].Position, gWorldViewProj);
			tempvert[2].Normal = mul(-normal3, (float3x3)gWorld);
			tempvert[2].TexCoord = outVertices[5].TexCoord;
			triStream.Append(tempvert[2]);
			
			triStream.RestartStrip();
			
			//v2 cap
			surfNormal = normalize(cross( (tempvert[2].Position - outVertices[5].Position),(tempvert[2].Position - outVertices[6].Position) ) );
		
			tempvert[2].Normal = surfNormal;
			outVertices[5].Normal = surfNormal;
			tempvert[1].Normal = surfNormal;
			outVertices[6].Normal = surfNormal;
			
			outVertices[5].TexCoord = tempvert[2].TexCoord;
			tempvert[1].TexCoord = tempvert[2].TexCoord;
			outVertices[6].TexCoord = tempvert[2].TexCoord;
			
			triStream.Append(tempvert[2]);
			triStream.Append(outVertices[5]);
			triStream.Append(tempvert[1]);
			triStream.Append(outVertices[6]);
			triStream.RestartStrip();
			
			//fragment v3
			outVertices[4].Position = mul(float4(explodedPosition[2],1),gWorldViewProj);
			outVertices[4].Normal = mul(vertices[2].Normal, (float3x3)gWorld);
			outVertices[4].TexCoord = vertices[2].TexCoord;
			triStream.Append(outVertices[4]);
						
			outVertices[6].Position = mul(float4(v3t1,1),gWorldViewProj);
			outVertices[6].Normal = mul(normal1, (float3x3)gWorld);
			outVertices[6].TexCoord = texCoord3;
			triStream.Append(outVertices[6]);
			
			outVertices[5].Position = mul(float4(v3t2,1),gWorldViewProj);
			outVertices[5].Normal = mul(normal2, (float3x3)gWorld);
			outVertices[5].TexCoord = texCoord2;
			triStream.Append(outVertices[5]);
			triStream.RestartStrip();
			
			//shell v3
			tempvert[0].Position = float4(explodedPosition[2],1) - m_Thickness* float4(normalize(outVertices[4].Normal), 0);
			tempvert[0].Position = mul(tempvert[0].Position, gWorldViewProj);
			tempvert[0].Normal = mul(-vertices[0].Normal, (float3x3)gWorld);
			tempvert[0].TexCoord = outVertices[4].TexCoord;
			triStream.Append(tempvert[0]);
			
			tempvert[1].Position = float4(v3t1,1) - m_Thickness* float4(normalize(outVertices[6].Normal), 0);
			tempvert[1].Position = mul(tempvert[1].Position, gWorldViewProj);
			tempvert[1].Normal = mul(-normal1, (float3x3)gWorld);
			tempvert[1].TexCoord = outVertices[6].TexCoord;
			triStream.Append(tempvert[1]);
			
			tempvert[2].Position = float4(v3t2,1) - m_Thickness* float4(normalize(outVertices[5].Normal), 0);
			tempvert[2].Position = mul(tempvert[2].Position, gWorldViewProj);
			tempvert[2].Normal = mul(-normal3, (float3x3)gWorld);
			tempvert[2].TexCoord = outVertices[5].TexCoord;
			triStream.Append(tempvert[2]);
			
			triStream.RestartStrip();
			
			//v3 cap
			surfNormal = normalize(cross( (tempvert[2].Position - outVertices[5].Position),(tempvert[2].Position - outVertices[6].Position) ) );
		
			tempvert[2].Normal = surfNormal;
			outVertices[5].Normal = surfNormal;
			tempvert[1].Normal = surfNormal;
			outVertices[6].Normal = surfNormal;
			
			outVertices[5].TexCoord = tempvert[2].TexCoord;
			tempvert[1].TexCoord = tempvert[2].TexCoord;
			outVertices[6].TexCoord = tempvert[2].TexCoord;
			
			triStream.Append(tempvert[2]);
			triStream.Append(outVertices[5]);
			triStream.Append(tempvert[1]);
			triStream.Append(outVertices[6]);
			triStream.RestartStrip();
			
			
			//fragment v4
			outVertices[4].Position = mul(float4(v4t1,1),gWorldViewProj);
			outVertices[4].Normal = mul(normal2, (float3x3)gWorld);
			outVertices[4].TexCoord = texCoord3;
			triStream.Append(outVertices[4]);//fix this one!
						
			outVertices[6].Position = mul(float4(v4t2,1),gWorldViewProj);
			outVertices[6].Normal = mul(normal1, (float3x3)gWorld);
			outVertices[6].TexCoord = texCoord2;
			triStream.Append(outVertices[6]);
			
			outVertices[5].Position = mul(float4(v4t3,1),gWorldViewProj);
			outVertices[5].Normal = mul(normal3, (float3x3)gWorld);
			outVertices[5].TexCoord = texCoord1;
			triStream.Append(outVertices[5]);
			triStream.RestartStrip();
			
			//shell v4
			tempvert[0].Position = float4(v4t1,1) - m_Thickness* float4(normalize(outVertices[4].Normal), 0);
			tempvert[0].Position = mul(tempvert[0].Position, gWorldViewProj);
			tempvert[0].Normal = mul(-vertices[0].Normal, (float3x3)gWorld);
			tempvert[0].TexCoord = outVertices[4].TexCoord;
			triStream.Append(tempvert[0]);
			
			tempvert[1].Position = float4(v4t2,1) - m_Thickness* float4(normalize(outVertices[6].Normal), 0);
			tempvert[1].Position = mul(tempvert[1].Position, gWorldViewProj);
			tempvert[1].Normal = mul(-normal1, (float3x3)gWorld);
			tempvert[1].TexCoord = outVertices[6].TexCoord;
			triStream.Append(tempvert[1]);
			
			tempvert[2].Position = float4(v4t3,1) - m_Thickness* float4(normalize(outVertices[5].Normal), 0);
			tempvert[2].Position = mul(tempvert[2].Position, gWorldViewProj);
			tempvert[2].Normal = mul(-normal3, (float3x3)gWorld);
			tempvert[2].TexCoord = outVertices[5].TexCoord;
			triStream.Append(tempvert[2]);
			
			triStream.RestartStrip();
			
			//v4 cap
			surfNormal = normalize(cross( (tempvert[2].Position - outVertices[5].Position),(tempvert[2].Position - outVertices[6].Position) ) );
		
			tempvert[2].Normal = surfNormal;
			outVertices[5].Normal = surfNormal;
			tempvert[1].Normal = surfNormal;
			outVertices[6].Normal = surfNormal;
			
			outVertices[5].TexCoord = tempvert[2].TexCoord;
			tempvert[1].TexCoord = tempvert[2].TexCoord;
			outVertices[6].TexCoord = tempvert[2].TexCoord;
			
			triStream.Append(tempvert[2]);
			triStream.Append(outVertices[5]);
			triStream.Append(tempvert[1]);
			triStream.Append(outVertices[6]);
			triStream.RestartStrip();
		}
	}
	
	triStream.RestartStrip();
}

[maxvertexcount(40)]
void GS(triangle VS_DATA vertices[3], inout TriangleStream<GS_DATA> triStream)
{
	CreateFragment(vertices, triStream);
}

//--------------------------------------------------------------------------------------
// Pixel Shader
//--------------------------------------------------------------------------------------
float4 PS(GS_DATA input) : SV_TARGET{

	input.Normal=-normalize(input.Normal);
	float alpha = gDiffuseMap.Sample(samLinear,input.TexCoord).a;
	float3 color = gDiffuseMap.Sample( samLinear,input.TexCoord ).rgb;
	float s = max(dot(gLightDirection,input.Normal), 0.4f);
	
	return float4(color*s,alpha);
}

//--------------------------------------------------------------------------------------
// Technique
//--------------------------------------------------------------------------------------
technique11 Default
{
    pass P0
    {
		SetRasterizerState(NoCulling);
		SetDepthStencilState(EnableDepth, 0);

		SetVertexShader(CompileShader(vs_4_0, VS()));
		SetGeometryShader(CompileShader(gs_4_0, GS()));
		SetPixelShader(CompileShader(ps_4_0, PS()));
    }
}
