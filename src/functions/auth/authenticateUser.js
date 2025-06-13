const {
  CognitoIdentityProviderClient,
  AdminInitiateAuthCommand,
} = require('@aws-sdk/client-cognito-identity-provider')

const cognitoClient = new CognitoIdentityProviderClient({
  region: process.env.AWS_REGION,
})

exports.handler = async (event) => {
  try {
    const { email, password } = JSON.parse(event.body)

    const authCommand = new AdminInitiateAuthCommand({
      UserPoolId: process.env.USER_POOL_ID,
      ClientId: process.env.USER_POOL_CLIENT_ID,
      AuthFlow: 'ADMIN_USER_PASSWORD_AUTH',
      AuthParameters: {
        USERNAME: email,
        PASSWORD: password,
      },
    })

    const response = await cognitoClient.send(authCommand)

    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
      body: JSON.stringify({
        message: 'Authentication successful',
        tokens: {
          accessToken: response.AuthenticationResult.AccessToken,
          idToken: response.AuthenticationResult.IdToken,
          refreshToken: response.AuthenticationResult.RefreshToken,
        },
      }),
    }
  } catch (error) {
    console.error('Error authenticating user:', error)
    return {
      statusCode: 401,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
      body: JSON.stringify({
        message: 'Authentication failed',
        error: error.message,
      }),
    }
  }
}
