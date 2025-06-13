const {
  CognitoIdentityProviderClient,
  AdminCreateUserCommand,
  AdminSetUserPasswordCommand,
} = require('@aws-sdk/client-cognito-identity-provider')

const cognitoClient = new CognitoIdentityProviderClient({
  region: process.env.AWS_REGION,
})

exports.handler = async (event) => {
  try {
    const { email, firstName, lastName, password } = JSON.parse(event.body)

    // Create user in Cognito
    const createUserCommand = new AdminCreateUserCommand({
      UserPoolId: process.env.USER_POOL_ID,
      Username: email,
      UserAttributes: [
        {
          Name: 'email',
          Value: email,
        },
        {
          Name: 'email_verified',
          Value: 'true',
        },
        {
          Name: 'given_name',
          Value: firstName,
        },
        {
          Name: 'family_name',
          Value: lastName,
        },
      ],
      MessageAction: 'SUPPRESS',
    })

    await cognitoClient.send(createUserCommand)

    // Set user password
    const setPasswordCommand = new AdminSetUserPasswordCommand({
      UserPoolId: process.env.USER_POOL_ID,
      Username: email,
      Password: password,
      Permanent: true,
    })

    await cognitoClient.send(setPasswordCommand)

    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
      body: JSON.stringify({
        message: 'User created successfully',
        email,
      }),
    }
  } catch (error) {
    console.error('Error creating user:', error)
    return {
      statusCode: 500,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
      body: JSON.stringify({
        message: 'Error creating user',
        error: error.message,
      }),
    }
  }
}
